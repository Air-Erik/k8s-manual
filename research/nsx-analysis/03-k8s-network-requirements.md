# Сетевые требования Kubernetes на NSX-T: Чек-лист

> **Цель документа:** Собрать все сетевые требования для развёртывания Kubernetes кластера на NSX-T.
> **Аудитория:** Оператор, который будет настраивать NSX-T.
> **Время чтения:** ~10 минут.

---

## Обзор: Что нужно от NSX-T для Kubernetes

Наш Kubernetes кластер требует от NSX-T следующего:

1. **Сеть для VM** (нод кластера) — L2 Segment с подсетью
2. **IP-адреса** для нод, API VIP, MetalLB pool
3. **Маршрутизацию** (Tier-1 → Tier-0 → Internet)
4. **Firewall правила** (DFW) для трафика между нодами
5. **Разрешение ARP** (SpoofGuard) для VIP и MetalLB
6. **Согласованный MTU** по всей цепочке
7. **(Опционально) NAT** для egress трафика

Давай разберём каждое требование подробно.

---

## 1. Segment для k8s-нод ✅

### Что нужно:

- **Один L2 Segment** для **всех** нод кластера (control plane + workers)
- Segment должен быть подключен к **Tier-1 Gateway** (который имеет uplink к Tier-0)

### Параметры Segment:

| Параметр | Требование | Пример |
|----------|-----------|---------|
| **Имя** | Уникальное (не пересекается с Tanzu) | `k8s-nodes-segment` или `VIP-VM` |
| **Подсеть (CIDR)** | /24 минимум (256 IP, ~250 используемых) | `192.168.100.0/24` |
| **Gateway IP** | Первый IP подсети (на Tier-1) | `192.168.100.1` |
| **DHCP** | Опционально (можно static IP) | Enabled или Disabled |
| **Transport Zone** | Существующая TZ | `overlay-tz` (или как у тебя) |
| **Tier-1 Gateway** | Подключен к Tier-0 | `k8s-tier1` (или существующий) |

### Чек-лист:

- [ ] Segment создан (или выбран существующий)
- [ ] Segment подключен к Tier-1 Gateway
- [ ] Tier-1 Gateway имеет маршрут к Tier-0
- [ ] Подсеть определена (например, 192.168.100.0/24)
- [ ] Gateway IP доступен (можно пинговать с тестовой VM)

---

## 2. IP-адресация (критично!) 🔢

### План выделения IP:

Тебе нужно зарезервировать IP для следующих целей:

| Назначение | Количество | Пример диапазона |
|------------|-----------|------------------|
| **Control Plane ноды** | 3 шт | `192.168.100.10-12` |
| **Worker ноды** | 2+ (запас 5+) | `192.168.100.20-30` |
| **API VIP** (kube-vip) | 1 шт | `192.168.100.100` |
| **MetalLB IP Pool** | 10-20 шт | `192.168.100.200-220` |
| **Запас** (для роста) | 20+ | `192.168.100.31-50` |
| **Gateway** | 1 (занят Tier-1) | `192.168.100.1` |

**Итого:** Минимум **40-50 IP** для начала (PoC), **80-100 IP** для Prod.

### Чек-лист:

- [ ] Подсеть имеет достаточно IP (минимум /25 = 128 IP, рекомендуется /24 = 256 IP)
- [ ] IP-план задокументирован (кто какой IP использует)
- [ ] IP **НЕ пересекаются** с Tanzu IP Pool
- [ ] IP **НЕ пересекаются** с DHCP pool (если DHCP используется)
- [ ] API VIP зарезервирован и не используется другими VM
- [ ] MetalLB pool зарезервирован и свободен
- [ ] DNS записи для API VIP созданы (опционально, но рекомендуется)

### Пример IP-плана (документируется в `nsx-configs/segments.md`):

```markdown
## IP Allocation Plan

| IP Range | Purpose | Notes |
|----------|---------|-------|
| 192.168.100.1 | Gateway (Tier-1) | Автоматически |
| 192.168.100.10-12 | Control Plane Nodes | cp-01, cp-02, cp-03 |
| 192.168.100.20-30 | Worker Nodes | w-01, w-02, ... (запас до 10 workers) |
| 192.168.100.100 | API VIP (kube-vip) | k8s-api.example.com |
| 192.168.100.200-220 | MetalLB Pool | Для Service LoadBalancer (20 IP) |
| 192.168.100.50-99 | Reserved | Запас для будущих нод |
```

---

## 3. Маршрутизация и внешняя связность 🌐

### Что нужно проверить:

| Требование | Проверка | Команда |
|-----------|---------|---------|
| **Tier-1 → Tier-0** | Uplink существует | NSX UI → Networking → Tier-1 → Tier-0 Connectivity |
| **Default route** | 0.0.0.0/0 → Tier-0 | NSX UI → Networking → Tier-1 → Routing |
| **Internet egress** | VM может достать 8.8.8.8 | `ping 8.8.8.8` с тестовой VM |
| **DNS resolution** | VM резолвит домены | `nslookup google.com` с тестовой VM |
| **vCenter доступен** | Для vSphere CSI | `curl -k https://<vcenter-IP>` с VM |

### NAT (если нужен):

- Если подсеть k8s-нод **приватная** (192.168.x.x), нужен **SNAT** для egress
- NAT настраивается на **Tier-0 или Tier-1 Gateway**
- Проверить: NSX UI → Networking → Tier-1 → NAT → SNAT правило

### Чек-лист:

- [ ] Tier-1 Gateway подключен к Tier-0
- [ ] Default route настроен
- [ ] Тестовая VM в сегменте может пинговать 8.8.8.8
- [ ] Тестовая VM может резолвить DNS (google.com)
- [ ] SNAT правило создано (если нужно)
- [ ] vCenter доступен с VM (для vSphere CSI)

---

## 4. Distributed Firewall (DFW) Rules 🔥

### Необходимые правила:

Kubernetes требует **много открытых портов** между нодами. Если у тебя настроены DFW правила с **default deny**, нужно **явно разрешить** следующий трафик:

#### Шаг 1: Создать группу "k8s-nodes"

**Опции:**
- По IP-адресам (192.168.100.10-30)
- По VM tags (vSphere tag "k8s-node")
- По имени VM (паттерн "k8s-*")

**Рекомендация:** По IP (проще для PoC), по тегам (лучше для Prod).

#### Шаг 2: Создать правила (приоритет выше deny-all)

| # | Name | Source | Destination | Ports | Action | Priority |
|---|------|--------|-------------|-------|--------|----------|
| 1 | k8s-inter-node | k8s-nodes | k8s-nodes | Any (или см. ниже) | Allow | 1000 |
| 2 | k8s-nodeport-ingress | Any | k8s-nodes | 80, 443, 30000-32767 | Allow | 1001 |
| 3 | k8s-egress | k8s-nodes | Any | Any | Allow | 1002 |

**Детализация портов для правила #1 (если хочешь быть точным):**

| Port | Protocol | Purpose |
|------|----------|---------|
| 6443 | TCP | Kubernetes API Server |
| 2379-2380 | TCP | etcd client/peer |
| 10250 | TCP | kubelet API |
| 10256 | TCP | kube-proxy healthz |
| 8472 | UDP | Cilium VXLAN (если используется) |
| 4240 | TCP | Cilium Health Check |
| 4244 | TCP | Cilium Hubble Server |

**Для PoC:** Можно открыть **Any** между k8s-nodes (проще).
**Для Prod:** Открыть только конкретные порты (безопаснее).

### Чек-лист:

- [ ] Группа `k8s-nodes` создана в NSX (Security → Groups)
- [ ] DFW правила созданы **ДО** default deny (приоритет 1000-1002)
- [ ] Правило 1: k8s-nodes → k8s-nodes (Any или конкретные порты) = Allow
- [ ] Правило 2: Any → k8s-nodes (80, 443, 30000-32767) = Allow
- [ ] Правило 3: k8s-nodes → Any = Allow (egress)
- [ ] Правила протестированы с тестовыми VM (ping, nc, curl)

---

## 5. SpoofGuard Whitelist ⚠️

### Проблема:

- **kube-vip** анонсирует API VIP через gratuitous ARP
- **MetalLB** анонсирует LoadBalancer IP через gratuitous ARP
- SpoofGuard видит, что VM отправляет ARP для IP, который **не назначен ей в vCenter**, и **блокирует**

### Решение:

**Вариант A (рекомендуется для Prod):** Добавить whitelist

- NSX UI → Security → SpoofGuard → Profiles
- Найти профиль для сегмента k8s-nodes (или создать новый)
- Добавить **Allowed IP Addresses**:
  - API VIP (например, 192.168.100.100)
  - MetalLB pool (например, 192.168.100.200-220)

**Вариант B (проще для PoC):** Отключить SpoofGuard на портах k8s-нод

- NSX UI → Security → SpoofGuard → Switching Profiles
- Найти профиль для сегмента → SpoofGuard = **Disabled**

⚠️ **Вариант B менее безопасен** (VM могут подменять IP), но проще для тестирования.

### Чек-лист:

- [ ] SpoofGuard проверен (включён или выключен?)
- [ ] Если включён: Whitelist создан для API VIP + MetalLB pool
- [ ] Если отключён: Задокументировано (для Prod нужно включить с whitelist)
- [ ] Проверка: На тестовой VM настроить secondary IP, пингануть с другой VM (должно работать)

---

## 6. MTU End-to-End 📏

### Почему это критично:

- Несогласованный MTU = фрагментация пакетов = таймауты, потеря соединений, медленная работа
- NSX overlay добавляет ~50-100 байт заголовков (Geneve)
- Cilium VXLAN добавляет ещё ~50 байт

### Цепочка MTU:

```
Physical Network (Underlay)
  MTU: обычно 1600 или 9000 (Jumbo Frames)
       ↓
NSX Transport Node Overlay
  MTU: проверить в NSX UI → System → Fabric → Nodes → Transport Nodes
  Обычно: 1600 (если underlay 1600+)
       ↓
VM vNIC (Node)
  MTU: должен быть МЕНЬШЕ overlay на ~100 байт
  Рекомендуется: 1500 (если overlay 1600)
       ↓
Cilium CNI (Pod Network)
  MTU: должен быть МЕНЬШЕ VM на ~50 байт
  Рекомендуется: 1450 (если VM 1500)
```

### Чек-лист:

- [ ] **Проверен MTU на NSX Transport Nodes** (NSX UI → System → Fabric → Nodes → Transport Nodes → Overlay MTU)
- [ ] **Задокументирован MTU для VM vNIC** (обычно 1500)
- [ ] **Рассчитан MTU для Cilium** = VM MTU - 50 (обычно 1450)
- [ ] **Протестирован MTU** с тестовыми VM:
  ```bash
  # Проверить текущий MTU на VM
  ip link show ens192

  # Тест ping с большим пакетом (без фрагментации)
  ping -M do -s 1400 <IP-другой-VM>

  # Если не проходит, уменьшать размер пока не пройдёт
  ping -M do -s 1200 <IP-другой-VM>
  ```

### Пример документации MTU (для `nsx-configs/segments.md`):

```markdown
## MTU Configuration

| Layer | MTU | Notes |
|-------|-----|-------|
| NSX Overlay (Transport Nodes) | 1600 | Проверено в NSX UI |
| VM vNIC (k8s nodes) | 1500 | Настраивается в Ubuntu |
| Cilium CNI (Pod network) | 1450 | Задаётся в Cilium values.yaml |

**Проверка:** `ping -M do -s 1400 <node-IP>` проходит без фрагментации ✅
```

---

## 7. DNS Servers 🌐

### Что нужно:

- VM-ноды должны резолвить домены:
  - `apt.kubernetes.io` (для установки kubeadm/kubelet)
  - `registry.k8s.io`, `ghcr.io`, `docker.io` (для образов контейнеров)
  - vCenter FQDN (для vSphere CSI)
  - Корпоративные домены (если есть)

### Настройка DNS:

**Вариант A:** Через DHCP (если DHCP включен на сегменте)
- NSX автоматически передаёт DNS servers из DHCP конфига

**Вариант B:** Статически в Ubuntu
- `/etc/netplan/` конфигурация или cloud-init

### Чек-лист:

- [ ] DNS servers определены (корпоративные или публичные 8.8.8.8, 8.8.4.4)
- [ ] DNS настроены в NSX Segment (если DHCP) или задокументированы для ручной настройки
- [ ] Проверка с тестовой VM:
  ```bash
  nslookup google.com
  nslookup apt.kubernetes.io
  nslookup <vcenter-fqdn>
  ```

---

## 8. Опциональные требования (для Prod)

### 8.1. NTP (Network Time Protocol)

- Все ноды должны иметь **синхронизированное время** (критично для etcd, certificates)
- Настраивается в Ubuntu через `systemd-timesyncd` или `chrony`
- NTP servers: корпоративные или публичные (pool.ntp.org)

### 8.2. Proxy (если есть)

- Если egress в интернет через корпоративный proxy:
  - Настроить `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` на нодах
  - Настроить containerd для работы через proxy

### 8.3. Сертификаты (если используется корпоративный CA)

- Если vCenter использует self-signed cert или корпоративный CA:
  - Добавить CA cert в trust store Ubuntu (`/usr/local/share/ca-certificates/`)

---

## Сводная таблица: Что нужно от NSX-T

| Требование | Обязательно? | Задача | Проверка |
|-----------|-------------|--------|---------|
| **Segment для k8s-нод** | ✅ Да | Создать или выбрать существующий | Сегмент виден в vSphere при создании VM |
| **IP-план** | ✅ Да | Зарезервировать IP (ноды, VIP, MetalLB) | Задокументировано в `nsx-configs/segments.md` |
| **Tier-1 → Tier-0** | ✅ Да | Проверить uplink | Тестовая VM пингует 8.8.8.8 |
| **DFW Rules** | ✅ Да | Создать группу и правила | Тестовые VM пингуют друг друга, `nc -zv` на порты OK |
| **SpoofGuard Whitelist** | ✅ Да | Добавить VIP + MetalLB или отключить | Gratuitous ARP не блокируется |
| **MTU проверен** | ✅ Да | Проверить NSX overlay, рассчитать для VM/Cilium | `ping -M do -s 1400` проходит |
| **DNS настроен** | ✅ Да | Указать DNS servers | `nslookup google.com` работает |
| **NAT (если нужен)** | ⚠️ Зависит | Создать SNAT для egress | VM достают интернет |
| **NTP** | 🟡 Рекомендуется | Настроить NTP на VM | `timedatectl` показывает sync |
| **Proxy** | 🟡 Если есть | Настроить переменные окружения | `curl` через proxy работает |

---

## Следующие шаги

Теперь у тебя есть полный чек-лист требований! 🎉

Следующий документ — **опросник** для исследования текущей NSX-T конфигурации. Я создам его сейчас, и ты заполнишь ответы, изучая NSX UI.

👉 **Переходим к Этапу 2: Исследование текущей конфигурации**

Я создам документ `04-current-config-questionnaire.md` прямо сейчас! 📋
