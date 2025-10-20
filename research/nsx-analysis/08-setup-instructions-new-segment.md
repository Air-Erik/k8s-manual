# Пошаговые инструкции: Создание нового сегмента k8s-nodes

> **Цель:** Создать новый NSX-T сегмент для Kubernetes нод
> **Время выполнения:** ~65 минут
> **Требования:** Права администратора в NSX Manager UI

---

## Обзор задачи

Мы создадим:
1. ✅ Новый Segment `k8s-nodes-segment` (172.16.50.0/24)
2. ✅ Tier-1 Gateway Interface для Gateway IP
3. ✅ DFW Group `k8s-nodes`
4. ✅ DFW Rules для K8s трафика
5. ✅ Валидацию с тестовыми VM

---

## ЧАСТЬ 1: Создание Segment (15 минут)

### Шаг 1.1: Открыть NSX Manager UI

```
URL: https://<your-nsx-manager-IP>
Login: admin (или твой account)
```

---

### Шаг 1.2: Создать новый Segment

**Путь:** `NSX UI → Networking → Segments → ADD SEGMENT`

**Параметры:**

| Поле | Значение | Комментарий |
|------|---------|-------------|
| **Segment Name** | `k8s-nodes-segment` | Понятное имя |
| **Connected Gateway** | `T1-GW-1` | Существующий Tier-1 |
| **Transport Zone** | `nsx-overlay-transportzone` | Как у VIP-VM |
| **Subnets** | `172.16.50.1/24` | Gateway IP + CIDR |

**Детальные шаги:**

1. Кликни **"ADD SEGMENT"** (синяя кнопка справа сверху)

2. **General Information:**
   - **Segment Name:** `k8s-nodes-segment`
   - **Connected Gateway:** Выбери из dropdown: `T1-GW-1`
   - **Transport Zone:** Выбери: `nsx-overlay-transportzone | Overlay`

3. **Subnets:**
   - Кликни **"SET SUBNETS"**
   - **Gateway IP Address:** `172.16.50.1/24`
   - (NSX автоматически создаст интерфейс на Tier-1)

4. **Advanced Configuration** (опционально, можно пропустить):
   - **DHCP Config:** `None` (не настраиваем, будем использовать static IP)
   - **Segment Profiles:** Оставь по умолчанию

5. **Кликни "SAVE"**

**Результат:**
- Segment `k8s-nodes-segment` появился в списке
- Статус: `Success` (зелёная галочка)
- Connected Gateway: `T1-GW-1`

---

### Шаг 1.3: Проверить в vCenter

**Путь:** `vCenter UI → Networking → Segments`

**Проверка:**
- ✅ Segment `k8s-nodes-segment` появился в списке
- ✅ Можно выбрать этот сегмент при создании VM (проверим позже)

---

## ЧАСТЬ 2: Проверка Tier-1 Gateway Interface (5 минут)

### Шаг 2.1: Открыть Tier-1 Gateway

**Путь:** `NSX UI → Networking → Tier-1 Gateways → T1-GW-1`

**Что проверить:**

1. **Tier-0 Connectivity:**
   - В секции "Tier-0 Gateway" должно быть: `T0-GW`
   - Статус: `Connected` ✅

2. **Interfaces:**
   - Перейди на вкладку **"Interfaces"**
   - Должен появиться новый интерфейс:
     - Name: `k8s-nodes-segment`
     - Type: `Segment`
     - IP Address: `172.16.50.1/24`
     - Status: `Success`

**Если интерфейс не появился:**
- Подожди 1-2 минуты (NSX создаёт интерфейс асинхронно)
- Обнови страницу (F5)
- Если всё ещё нет → вернись к Шагу 1.2, проверь "Subnets" настройку

---

## ЧАСТЬ 3: Создание DFW Group для K8s (5 минут)

### Шаг 3.1: Создать группу k8s-nodes

**Путь:** `NSX UI → Inventory → Groups → ADD GROUP`

**Параметры:**

| Поле | Значение |
|------|---------|
| **Group Name** | `k8s-nodes` |
| **Description** | `Kubernetes cluster nodes` |
| **Membership Criteria** | IP Address |
| **IP Address** | `172.16.50.0/24` |

**Детальные шаги:**

1. Кликни **"ADD GROUP"**

2. **General:**
   - **Name:** `k8s-nodes`
   - **Description:** `Kubernetes cluster nodes (all control plane and workers)`

3. **Compute Members:**
   - **Member Type:** Выбери `IP Address`
   - Кликни **"SET MEMBERS"**

4. **IP Address Membership:**
   - Кликни **"Add Criteria"**
   - **Criteria:** `IP Address`
   - **Operator:** `Equals`
   - **Value:** `172.16.50.0/24`
   - Кликни **"APPLY"**

5. **Кликни "SAVE"**

**Результат:**
- Группа `k8s-nodes` создана
- Membership: `IP Address = 172.16.50.0/24`
- VM Count: `0` (пока нет VM в этом сегменте)

---

## ЧАСТЬ 4: Создание DFW Rules для K8s (10 минут)

### Шаг 4.1: Открыть Distributed Firewall

**Путь:** `NSX UI → Security → Distributed Firewall`

**Что видишь:**
- Несколько категорий (для Tanzu/NCP)
- Default Rules (NDP, DHCP, Layer3)

---

### Шаг 4.2: Создать новую секцию для K8s

**Зачем:** Чтобы правила K8s были отдельно и понятно где они.

**Шаги:**

1. В списке правил, найди место **ПЕРЕД** дефолтными правилами (Default Layer3 Rule)
2. Кликни **"ADD POLICY"** (или "ADD SECTION" в зависимости от версии NSX UI)
3. **Name:** `Kubernetes Cluster (k8s-nodes)`
4. **Applied To:** `k8s-nodes` (группа, которую мы создали)
5. **Кликни "SAVE"**

**Результат:** Новая пустая секция создана.

---

### Шаг 4.3: Создать Rule 1 — Inter-Node Communication

**Назначение:** Разрешить трафик между K8s нодами (API, etcd, kubelet, CNI).

**Шаги:**

1. В секции "Kubernetes Cluster", кликни **"ADD RULE"**

2. **Параметры:**
   - **Name:** `k8s-inter-node-allow`
   - **Sources:** `k8s-nodes` (группа)
   - **Destinations:** `k8s-nodes` (группа)
   - **Services:** `Any` (или конкретные порты, см. ниже)
   - **Profiles:** `None`
   - **Action:** `Allow`
   - **Applied To:** `k8s-nodes`

3. **Кликни "PUBLISH"** (или "SAVE")

**Альтернатива (более безопасно, для Prod):**

Вместо `Services: Any`, создай Service Group с портами:
- TCP 6443 (Kubernetes API)
- TCP 2379-2380 (etcd)
- TCP 10250 (kubelet)
- TCP 4240 (Cilium Health)
- UDP 8472 (Cilium VXLAN)
- TCP 30000-32767 (NodePort)

**Для PoC:** Используй `Any` (проще). **Для Prod:** Используй конкретные порты.

---

### Шаг 4.4: Создать Rule 2 — Ingress (NodePort, Ingress Controller)

**Назначение:** Разрешить внешний трафик к K8s сервисам.

**Шаги:**

1. Кликни **"ADD RULE"** (в той же секции)

2. **Параметры:**
   - **Name:** `k8s-ingress-allow`
   - **Sources:** `Any`
   - **Destinations:** `k8s-nodes`
   - **Services:**
     - HTTP (80)
     - HTTPS (443)
     - NodePort Range: 30000-32767 (если нет готового сервиса, создай: `TCP 30000-32767`)
   - **Action:** `Allow`
   - **Applied To:** `k8s-nodes`

3. **Кликни "PUBLISH"**

**Как создать NodePort Service (если нет в списке):**
- NSX UI → Inventory → Services → ADD SERVICE
- Name: `NodePort-Range`
- Service Type: `TCP`
- Source Ports: `Any`
- Destination Ports: `30000-32767`
- SAVE

---

### Шаг 4.5: Создать Rule 3 — Egress (Internet, Repos, vCenter)

**Назначение:** Разрешить K8s нодам ходить в интернет (apt, docker registry, vCenter API).

**Шаги:**

1. Кликни **"ADD RULE"**

2. **Параметры:**
   - **Name:** `k8s-egress-allow`
   - **Sources:** `k8s-nodes`
   - **Destinations:** `Any`
   - **Services:** `Any`
   - **Action:** `Allow`
   - **Applied To:** `k8s-nodes`

3. **Кликни "PUBLISH"**

---

### Шаг 4.6: Проверить порядок правил

**Важно:** Правила должны быть **ВЫШЕ** дефолтных deny-правил.

**Порядок (сверху вниз):**
```
1. Kubernetes Cluster (k8s-nodes) ← Наша секция
   - k8s-inter-node-allow
   - k8s-ingress-allow
   - k8s-egress-allow
2. ds-domain-... (Tanzu/NCP правила)
3. Default Rule NDP
4. Default Rule DHCP
5. Default Layer3 Rule (Drop)
```

**Если порядок неправильный:**
- Используй стрелки **↑↓** (Move Up/Down) для изменения порядка секций

---

## ЧАСТЬ 5: Валидация с тестовыми VM (30 минут)

### Шаг 5.1: Создать 2 тестовые VM

**В vCenter:**

1. **VM 1:**
   - Name: `k8s-test-01`
   - OS: Ubuntu 22.04 или 24.04 (любой Linux)
   - vCPU: 1
   - RAM: 2 GB
   - Disk: 20 GB
   - Network: `k8s-nodes-segment` ← **ВАЖНО!**
   - IP: **Статический `172.16.50.10`** (настроить в Ubuntu после создания)

2. **VM 2:**
   - Name: `k8s-test-02`
   - (те же параметры)
   - Network: `k8s-nodes-segment`
   - IP: **Статический `172.16.50.11`**

**Настройка статического IP в Ubuntu:**

```bash
# На каждой VM после первого запуска:

# Узнать имя интерфейса
ip link show

# Обычно: ens192 или eth0
# Создать netplan конфиг:
sudo nano /etc/netplan/01-netcfg.yaml

# Содержимое для VM 1 (172.16.50.10):
network:
  version: 2
  ethernets:
    ens192:  # Измени на твой интерфейс
      dhcp4: no
      addresses:
        - 172.16.50.10/24
      routes:
        - to: default
          via: 172.16.50.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

# Применить:
sudo netplan apply

# Проверить:
ip addr show ens192
```

(Для VM 2 используй `172.16.50.11`)

---

### Шаг 5.2: Тест 1 — Ping Gateway

**На VM 1:**

```bash
ping 172.16.50.1

# Ожидается: пинги проходят
# PING 172.16.50.1 56(84) bytes of data.
# 64 bytes from 172.16.50.1: icmp_seq=1 ttl=64 time=0.5 ms
```

**Результат:** ✅ Pass / ❌ Fail

**Если не работает:**
- Проверь, что VM подключена к сегменту `k8s-nodes-segment` (vCenter → VM → Network Adapter)
- Проверь статический IP в Ubuntu: `ip addr show`
- Проверь Tier-1 Interface: NSX UI → Networking → Tier-1 → T1-GW-1 → Interfaces

---

### Шаг 5.3: Тест 2 — Ping between VMs

**На VM 1:**

```bash
ping 172.16.50.11

# Ожидается: пинги проходят
```

**Результат:** ✅ Pass / ❌ Fail

**Если не работает:**
- Проверь DFW Rule 1 (`k8s-inter-node-allow`)
- NSX UI → Security → Distributed Firewall → проверь, что правило **Published** и **Applied**
- Проверь порядок правил (k8s правила ВЫШЕ default deny)

---

### Шаг 5.4: Тест 3 — Ping Internet

**На VM 1:**

```bash
ping 8.8.8.8

# Ожидается: пинги проходят
```

**Результат:** ✅ Pass / ❌ Fail

**Если не работает:**
- Проверь DFW Rule 3 (`k8s-egress-allow`)
- Проверь Tier-1 → Tier-0 connectivity (NSX UI → Tier-1 → T1-GW-1 → Tier-0 Gateway = T0-GW)
- Проверь default route на VM: `ip route show` (должен быть `default via 172.16.50.1`)

---

### Шаг 5.5: Тест 4 — DNS Resolution

**На VM 1:**

```bash
nslookup google.com

# Ожидается: возвращает IP-адреса
```

**Результат:** ✅ Pass / ❌ Fail

**Если не работает:**
- Проверь DNS в netplan (должны быть 8.8.8.8, 8.8.4.4)
- Проверь `/etc/resolv.conf`: `cat /etc/resolv.conf`
- Проверь DFW: egress должен разрешать UDP 53 (DNS)

---

### Шаг 5.6: Тест 5 — MTU Check

**На VM 1:**

```bash
# Тест с большим пакетом (без фрагментации)
ping -M do -s 1400 172.16.50.11

# Ожидается: пинги проходят
```

**Результат:** ✅ Pass / ❌ Fail

**Если не работает:**
- MTU слишком большой для overlay
- Уменьши MTU на VM: `sudo ip link set dev ens192 mtu 1450`
- Повтори тест с `-s 1200`

**Задокументируй рабочее значение MTU** (для Cilium конфигурации).

---

### Шаг 5.7: Тест 6 — vCenter Access

**На VM 1:**

```bash
# Замени <vcenter-IP> на реальный IP vCenter
curl -k https://<vcenter-IP>

# Ожидается: HTML страница или JSON (не timeout)
```

**Результат:** ✅ Pass / ❌ Fail

**Если не работает:**
- Проверь egress DFW rule
- Проверь, что vCenter доступен: `ping <vcenter-IP>`

---

### Шаг 5.8: Тест 7 — Gratuitous ARP (SpoofGuard)

**Этот тест проверяет, заблокирует ли SpoofGuard kube-vip/MetalLB ARP.**

**На VM 1:**

```bash
# Добавить secondary IP (как будет делать kube-vip)
sudo ip addr add 172.16.50.100/24 dev ens192

# Отправить gratuitous ARP
sudo arping -c 3 -A -I ens192 172.16.50.100
```

**На VM 2:**

```bash
# Пингануть VIP
ping 172.16.50.100

# Проверить ARP-таблицу
arp -n | grep 172.16.50.100
# Должен показать MAC-адрес VM 1
```

**Результат:** ✅ Pass (VIP пингуется) / ❌ Fail (timeout)

**Если не работает:**
- SpoofGuard блокирует!
- Нужно искать SpoofGuard в NSX UI и добавлять whitelist
- Или отключить SpoofGuard для k8s-nodes сегмента

**После теста очисти:**

```bash
# На VM 1:
sudo ip addr del 172.16.50.100/24 dev ens192
```

---

### Шаг 5.9: Итоговая валидация

**Чек-лист:**

- ✅ Gateway пингуется (172.16.50.1)
- ✅ Ping между VM (172.16.50.10 ↔ 172.16.50.11)
- ✅ Ping Internet (8.8.8.8)
- ✅ DNS работает (nslookup google.com)
- ✅ MTU корректен (ping -M do -s 1400 проходит)
- ✅ vCenter доступен
- ✅ Gratuitous ARP работает (SpoofGuard не блокирует)

**Если ВСЕ тесты ✅ → ГОТОВО! Можно удалять тестовые VM и начинать deploy K8s нод.**

---

## ЧАСТЬ 6: Финальная документация (10 минут)

### Шаг 6.1: Заполнить nsx-configs/segments.md

**Открой:** `nsx-configs/segments.md`

**Заполни секции:**
- Segment Information (имя, подсеть, gateway, Tier-1)
- IP Allocation Plan (таблица с IP-адресами)
- MTU Configuration (значения из тестов)
- DNS Configuration (8.8.8.8, 8.8.4.4 или корпоративные)
- DFW Rules (статус: настроены, ссылка на экспорт)
- SpoofGuard (статус: не блокирует / настроен whitelist)
- Validation (все чек-листы ✅)

---

### Шаг 6.2: (Опционально) Экспорт DFW Rules

**Если хочешь сохранить DFW правила как JSON:**

**Путь:** `NSX UI → Security → Distributed Firewall → Export`

**Сохрани файл как:** `nsx-configs/dfw-rules-k8s.json`

---

### Шаг 6.3: (Опционально) Скриншоты

**Сделай скриншоты:**
1. NSX UI → Networking → Segments → k8s-nodes-segment (детали)
2. NSX UI → Security → Distributed Firewall (правила k8s)
3. NSX UI → Inventory → Groups → k8s-nodes (членство)

**Сохрани в:** `research/nsx-analysis/screenshots/`

---

## Troubleshooting (если что-то пошло не так)

### Проблема: Segment не появился в vCenter

**Решение:**
- Подожди 2-3 минуты (синхронизация NSX → vCenter)
- Обнови список в vCenter (F5)
- Проверь, что NSX Compute Manager добавлен: NSX UI → System → Fabric → Compute Managers
- Проверь статус сегмента: NSX UI → Segments → k8s-nodes-segment → Status должен быть `Realized`

---

### Проблема: Ping gateway не работает

**Решение:**
1. Проверь IP на VM: `ip addr show` (должен быть 172.16.50.10/24)
2. Проверь route: `ip route show` (должен быть `default via 172.16.50.1`)
3. Проверь Tier-1 Interface: NSX UI → Tier-1 → T1-GW-1 → Interfaces (должен быть интерфейс с IP 172.16.50.1)
4. Проверь, что VM подключена к правильному сегменту: vCenter → VM → Edit Settings → Network Adapter → Network Label = `k8s-nodes-segment`

---

### Проблема: Ping между VM не работает

**Решение:**
1. Проверь DFW Rule 1: NSX UI → Security → DFW → `k8s-inter-node-allow` → Applied To = `k8s-nodes`
2. Проверь, что группа `k8s-nodes` содержит подсеть 172.16.50.0/24: NSX UI → Inventory → Groups → k8s-nodes → Members
3. Проверь порядок правил: k8s правила должны быть ВЫШЕ default deny
4. Проверь статус правила: должно быть `Published` (не `Draft`)

---

### Проблема: Ping Internet не работает

**Решение:**
1. Проверь DFW Rule 3 (egress): должен разрешать `k8s-nodes → Any`
2. Проверь Tier-1 → Tier-0: NSX UI → Tier-1 → T1-GW-1 → Tier-0 Gateway должен быть `T0-GW` и статус `Connected`
3. Проверь default route на VM: `ip route show` (должен быть gateway 172.16.50.1)
4. Попробуй пингануть gateway: `ping 172.16.50.1` (должен работать)

---

### Проблема: DNS не работает

**Решение:**
1. Проверь `/etc/resolv.conf`: должны быть nameservers (8.8.8.8, 8.8.4.4)
2. Проверь netplan: `cat /etc/netplan/01-netcfg.yaml` → nameservers должны быть указаны
3. Применить netplan заново: `sudo netplan apply`
4. Проверь egress DFW: должен разрешать UDP 53 (DNS)

---

### Проблема: Gratuitous ARP не работает (SpoofGuard блокирует)

**Решение:**
1. Найди SpoofGuard в NSX UI:
   - Попробуй: Networking → Segments → k8s-nodes-segment → Security
   - Или: System → Profiles → Segment Profiles → Segment Security
2. Добавь whitelist:
   - Allowed IP Addresses: `172.16.50.100` (API VIP)
   - И диапазон: `172.16.50.200-220` (MetalLB pool)
3. Или отключи SpoofGuard для k8s-nodes сегмента (менее безопасно, но проще для PoC)

---

## Итоговый чек-лист

**Перед переходом к K8s deployment, убедись:**

- ✅ Segment `k8s-nodes-segment` создан (172.16.50.0/24)
- ✅ Tier-1 Interface настроен (Gateway IP: 172.16.50.1)
- ✅ DFW Group `k8s-nodes` создана
- ✅ DFW Rules настроены (inter-node, ingress, egress)
- ✅ Все валидационные тесты пройдены (connectivity, MTU, DNS, ARP)
- ✅ Документация заполнена (`nsx-configs/segments.md`)

**Если все ✅ → Переходи к Этапу 0.2 (VM Preparation)!** 🎉

---

**Поздравляю! NSX-T готов для Kubernetes! 🚀**

Следующий шаг: Создание VM-шаблонов для K8s нод (Ubuntu 24.04 + kubeadm + containerd).
