# NSX-T: Шаблон создания T1 под кластер Kubernetes (вариант “один T1 на кластер”)

Этот гайд — пошаговая инструкция, чтобы быстро поднимать изолированную сеть для k8s-кластера в NSX‑T: создаём **Tier‑1**, **overlay‑сегмент** сети узлов, **NAT** (No‑SNAT + SNAT), подключаем ВМ/ноды и (опционально) настраиваем **Ingress** через NSX Load Balancer или DNAT.  
Подходит для схемы, где у вас **Tier‑0 уже подключён к “внешней” VLAN (например, 172.16.50.0/24) и имеет default‑route в периметр/интернет**.

---

## 0) Предварительный план адресов (заполните под себя)

```text
# Параметры для НОВОГО КЛАСТЕРА
CLUSTER_NAME         = k8s-<env>-<team>          # напр. k8s-zeon-dev
NODE_SUBNET_CIDR     = 10.246.10.0/24            # сеть узлов кластера (overlay)
NODE_GW_IP           = 10.246.10.1/24            # шлюз сегмента (LIF T1)
VIP_POOL_CIDR        = 172.16.50.192/27          # пул VIP'ов для Ingress/LB (внешняя VLAN)
EGRESS_SNAT_IP       = 172.16.50.230             # свободный IP во внешней VLAN для SNAT
DNS_IPS              = 172.17.10.3,8.8.8.8       # DNS сервера для нод/ВМ
T0_NAME              = TO-GW                     
EDGE_CLUSTER         = EC-1                       # ваш Edge Cluster
TRANSPORT_ZONE       = nsx-overlay-transportzone  # Overlay TZ
```

> **Важно:** не пересекайтесь с уже используемыми сетями (например, в вашем окружении Tanzu использует `10.244.0.0/20` и внутренние 100.64.0.0/10 для T0↔T1).  
> Подсети **Pods/Services** в самом k8s задаются отдельно (например, Pods `10.200.0.0/16`, Services `10.96.0.0/12`). Они **не равны** сети узлов и не должны с ней пересекаться.

---

## 1) Создание Tier‑1 Gateway

**Путь:** `Networking → Tier‑1 Gateways → ADD TIER‑1 GATEWAY`

Заполните:
- **Name:** `T1-<CLUSTER_NAME>` (напр. `T1-k8s-zeon-dev`)
- **HA Mode:** `Active-Standby`  _(требуется для NAT/LB)_
- **Linked Tier‑0 Gateway:** `T0_NAME` (напр. `TO-GW`)
- **Edge Cluster:** `EDGE_CLUSTER` (напр. `EC-1`)
- **Edges Pool Allocation Size:** `ROUTING` _(минимум; поменяете на LB_SMALL, если включите NSX-LB)_
- **Route Advertisement → включить:**
  - **All Connected Segments & Service Ports = Yes** ✅
  - **All NAT IPs = Yes** ✅ (нужно, чтобы T0 «видел» NAT/VIP маршруты T1)
  - (опц.) **All LB VIP Routes** и **All LB SNAT IP Routes** = Yes, если планируете NSX‑LB

**Save → Publish.**

---

## 2) Создание overlay‑сегмента сети узлов

**Путь:** `Networking → Segments → ADD SEGMENT`

Заполните:
- **Segment Name:** `seg-<CLUSTER_NAME>-nodes` (напр. `seg-k8s-zeon-dev-nodes`)
- **Connected Gateway:** `T1-<CLUSTER_NAME>` (напр. `T1-k8s-zeon-dev`)
- **Transport Zone:** `TRANSPORT_ZONE` (Overlay)
- **Subnets → Gateway CIDR IP:** `NODE_GW_IP` (напр. `10.246.10.1/24`) → это **шлюз** для нод
- **(Опц.) SET DHCP CONFIG**, если хотите раздавать IP из NSX:
  - **DHCP Server Address:** свободный IP внутри сети (напр. `10.246.10.2/24`)
  - **DHCP Ranges:** напр. `10.246.10.100-10.246.10.200`
  - **IPv4 Gateway:** подставится автоматически (`10.246.10.1/24`)
  - **DNS Servers:** `DNS_IPS`

**Save → Publish.**

> Частая ошибка: в поле *Gateway CIDR IP* вводят **сеть (`10.246.10.0/24`)**, а не **адрес шлюза** (`10.246.10.1/24`). Должен быть именно **адрес**, не сеть.

---

## 3) Подключение ВМ/нод к сегменту + сеть внутри ВМ

В vSphere у ВМ: **Edit Settings → Network adapter →** выбрать сегмент `seg-<CLUSTER_NAME>-nodes`.

Если без DHCP, на каждой ВМ/ноде пропишите **статику**:
- **IP:** свободный из `NODE_SUBNET_CIDR` (напр. `10.246.10.10/24`)
- **Gateway:** `10.246.10.1`
- **DNS:** `DNS_IPS`

Пример для Ubuntu (netplan):
```yaml
# /etc/netplan/01-k8s.yaml
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.246.10.10/24]
      gateway4: 10.246.10.1
      nameservers:
        addresses: [172.17.10.3, 8.8.8.8]
```
```bash
sudo netplan apply
```

---

## 4) NAT на T1: No‑SNAT (исключения) + SNAT (egress)

**Путь:** `Networking → NAT → Gateway: T1-<CLUSTER_NAME>`

### 4.1 No‑SNAT к VIP‑пулу (обязательное исключение)
**Зачем:** когда поды/ноды обращаются к Ingress‑VIP (health‑checks/внутренние вызовы), исходный адрес **не должен** переодеваться. Это исключает hairpin‑проблемы и сохраняет реальный IP клиента в логах.

- **Name:** `no_snat_to_vips`
- **Action:** `No SNAT`
- **Source IP:** `NODE_SUBNET_CIDR` (напр. `10.246.10.0/24`)
- **Destination IP | Port:** `VIP_POOL_CIDR` (напр. `172.16.50.192/27`)
- **Logging:** `On`
- **Priority:** `10`

### 4.2 (Опционально) No‑SNAT к внутренним сетям
**Зачем:** если нодам нужно ходить **без NAT** во внутренние сети (например, к приватному registry/CI).  
> Помните: у этих сетей должна быть **обратная маршрутизация** в `NODE_SUBNET_CIDR`.

- **Name:** `no_snat_to_internal`
- **Action:** `No SNAT`
- **Source IP:** `NODE_SUBNET_CIDR`
- **Destination IP:** список нужных внутренних сетей (напр. `172.16.100.0/24`, `172.16.50.0/24`)
- **Priority:** `20`
- **Logging:** `On`

### 4.3 SNAT (catch‑all egress в интернет)
**Зачем:** всё остальное исходящее «маскируем» в один внешний IP — **интернет заработает без маршрутов на апстриме**.

- **Name:** `snat_to_internet`
- **Action:** `SNAT`
- **Source IP:** `NODE_SUBNET_CIDR` (напр. `10.246.10.0/24`)
- **Destination IP | Port:** _пусто_ (любой)
- **Translated IP:** `EGRESS_SNAT_IP` (напр. `172.16.50.230`)
- **Priority:** `100`
- **Logging:** `On`

> **Порядок правил важен:** все **No‑SNAT** стоят **выше**, **SNAT** — ниже.  
> После добавления нажмите **Publish** и проверьте, что у SNAT **растут Hits** (счётчики срабатываний).

---

## 5) (Опционально) Ingress для сервисов

### Вариант A — NSX‑T Load Balancer (рекомендуется)
1. Включите Load Balancer на T1 (`Allocation Size` → `LB_SMALL` при необходимости).
2. Создайте:
   - **Service Monitor** (HTTP/HTTPS),
   - **Pool** — backend: NodePort’ы `ingress-nginx` на нодах (напр. `10.246.10.x:30080/30443`),
   - **Virtual Server (VIP)**: IP из `VIP_POOL_CIDR` (напр. `172.16.50.200:80/443`) → привязать к пулу.
3. В DNS направьте домены на этот VIP.

### Вариант B — DNAT на NodePort (быстрый старт, без LB)
Создайте по правилу на порт:
- **DNAT:** `172.16.50.200:443 → 10.246.10.10:30443`
- **DNAT:** `172.16.50.200:80  → 10.246.10.10:30080`

Минусы DNAT: нет балансировки/health‑checks, привязка к конкретной ноде.

---

## 6) Firewall‑политики (минимум для запуска)

- **Gateway Firewall (T0/T1):** оставьте `Allow` по умолчанию, если он у вас и так разрешающий.
- **Distributed Firewall (DFW):**
  - Создайте группу `grp-<CLUSTER_NAME>-nodes` (по сегменту или тегам ВМ).
  - На время запуска дайте простое `Allow egress` для группы.
  - Позже сузьте правила (доступы в реестры, апдейты, исходящие 443 и т.д.).

---

## 7) Проверка и отладка

**На ВМ/ноде:**
```bash
ip addr
ip route | grep default            # должен вести на NODE_GW_IP
ping -c3 NODE_GW_IP                # пинг шлюза
tracepath -n 8.8.8.8               # где «ломается» маршрут
curl -s ifconfig.co                # должен показать внешний IP/путь
nslookup google.com 8.8.8.8        # проверка DNS
```

**В NSX:**
- `T1 → NAT`: у `snat_to_internet` растут **Hits**.
- `Plan & Troubleshoot → Traceflow`: источник — порт ВМ, назначение — `8.8.8.8` (увидите, где дроп).
- `Tier‑1 → Route Advertisement`: включены флаги как в шаге 1.

**Типовые ошибки:**
- В сегменте указали **сеть** вместо **адреса шлюза**.
- Забыт **SNAT** или он ниже по приоритету какого‑то правила.
- Включили `No‑SNAT` к внутренним сетям, но **нет обратного маршрута** — трафик не возвращается.
- DFW режет egress (временно дайте Allow для группы кластера).

---

## 8) Масштабирование: ещё кластеры

Повторяйте шаги 1–7 на **новом T1** с **новой /24** из вашего блока и **новым SNAT‑IP**.  
Пример адресации:
| Кластер           | Сеть узлов (/24) | Шлюз (T1 LIF) | SNAT IP        | Примечание |
|-------------------|------------------|---------------|----------------|------------|
| k8s-zeon-dev      | 10.246.10.0/24   | 10.246.10.1   | 172.16.50.230  | VIP: 172.16.50.200 |
| k8s-zeon-stage    | 10.246.20.0/24   | 10.246.20.1   | 172.16.50.231  | VIP: 172.16.50.201 |
| k8s-zeon-prod     | 10.246.30.0/24   | 10.246.30.1   | 172.16.50.232  | VIP: 172.16.50.202 |

> Если свободных адресов во внешней VLAN мало, допускается использовать **один SNAT‑IP** для нескольких «лёгких» кластеров, но лучше — по одному IP на кластер (проще диагностика и больше запас по сессиям).

---

### Быстрый чек‑лист (сводно)

- [ ] Создан `T1-<CLUSTER_NAME>`, привязан к `T0`, включён Route Advertisement.
- [ ] Создан overlay‑сегмент `seg-<CLUSTER_NAME>-nodes`, `Gateway CIDR = NODE_GW_IP`.
- [ ] ВМ/ноды подключены к сегменту; IP/шлюз/DNS выставлены.
- [ ] На T1 созданы NAT‑правила: `no_snat_to_vips` (и, при нужде, `no_snat_to_internal`) **выше**, `snat_to_internet` **ниже**.
- [ ] SNAT‑правило получает **Hits**.
- [ ] (Опц.) NSX‑LB или DNAT для внешнего доступа к сервисам.
- [ ] DFW/GW‑FW не блокируют egress.

Удачных запусков! 🚀
