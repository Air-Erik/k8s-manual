# Чек-лист валидации NSX-T для Kubernetes

> **Цель:** Проверить, что все настройки NSX-T применены корректно и готовы для развёртывания K8s.
> **Когда использовать:** После применения инструкций из 07 или 08 документов.

---

## Как использовать этот чек-лист

1. Применил настройки NSX-T (DFW, SpoofGuard, etc.)
2. Создал 1-2 **тестовые VM** в сегменте k8s-nodes (или VIP-VM)
3. Проходи по каждому пункту чек-листа
4. Отмечай `[x]` если проверка пройдена, `[ ]` если нет
5. Если что-то не работает — см. раздел **Troubleshooting** внизу

---

## РАЗДЕЛ 1: Segment и Tier-1 Gateway ✅

### 1.1. Segment доступен

- [ ] **Сегмент виден в vSphere** при создании VM (в списке Networks)
- [ ] **Можно создать VM** и подключить её к этому сегменту
- [ ] VM получает **IP-адрес** (статический или через DHCP)

**Как проверить:**
- vCenter → Create VM → Network → выбрать сегмент → должен быть в списке
- После создания VM: посмотреть IP в vCenter или зайти в VM и выполнить `ip addr show`

---

### 1.2. Gateway доступен

- [ ] **Gateway IP отвечает на ping** с тестовой VM

**Как проверить:**
```bash
# На тестовой VM:
ping <gateway-IP>   # например, ping 192.168.100.1

# Должен отвечать (пинг проходит)
```

---

### 1.3. IP-план

- [ ] **IP-план задокументирован** в `nsx-configs/segments.md`
- [ ] **Свободных IP достаточно** для всех нод + VIP + MetalLB (минимум 29)
- [ ] **MetalLB pool НЕ пересекается** с DHCP pool или существующими VM

**Проверить:**
- Открыть `nsx-configs/segments.md` → должна быть таблица с IP allocation
- Пингануть все IP из MetalLB pool: `for i in {200..220}; do ping -c 1 -W 1 192.168.100.$i; done`
  - Все должны быть **недоступны** (не отвечают) — значит свободны

---

## РАЗДЕЛ 2: External Connectivity 🌐

### 2.1. Интернет доступен

- [ ] **Можно пингануть 8.8.8.8** с тестовой VM

**Как проверить:**
```bash
# На тестовой VM:
ping 8.8.8.8

# Если не работает:
# - Проверь Tier-1 → Tier-0 uplink
# - Проверь NAT rules (если подсеть приватная)
# - Проверь DFW egress rules
```

---

### 2.2. DNS работает

- [ ] **DNS резолвит домены** с тестовой VM

**Как проверить:**
```bash
# На тестовой VM:
nslookup google.com
nslookup apt.kubernetes.io

# Должны вернуть IP-адреса

# Если не работает:
# - Проверь DNS servers в VM: cat /etc/resolv.conf
# - Проверь DNS в DHCP (если используется)
# - Настрой DNS вручную в /etc/netplan/
```

---

### 2.3. vCenter доступен

- [ ] **vCenter API отвечает** с тестовой VM (нужно для vSphere CSI)

**Как проверить:**
```bash
# На тестовой VM:
curl -k https://<vcenter-IP-or-FQDN>

# Должна вернуться HTML страница или JSON (не timeout/connection refused)
```

---

## РАЗДЕЛ 3: Distributed Firewall (DFW) 🔥

### 3.1. Группа k8s-nodes создана

- [ ] **Группа существует** в NSX UI

**Как проверить:**
- NSX UI → Inventory → Groups → найти группу "k8s-nodes" (или как ты назвал)

---

### 3.2. DFW правила применены

- [ ] **Правила созданы** с правильным приоритетом (выше deny-all)
- [ ] **Правило 1:** k8s-nodes → k8s-nodes = Allow
- [ ] **Правило 2:** Any → k8s-nodes (NodePort, Ingress) = Allow
- [ ] **Правило 3:** k8s-nodes → Any (egress) = Allow

**Как проверить:**
- NSX UI → Security → Distributed Firewall → найти правила
- Priority должен быть ~1000-1002 (выше default deny)

---

### 3.3. Трафик между VM разрешён

- [ ] **Две тестовые VM могут пинговать друг друга**

**Как проверить:**
```bash
# Создай 2 тестовые VM в сегменте k8s-nodes (или VIP-VM)
# VM1: 192.168.100.10
# VM2: 192.168.100.11

# На VM1:
ping 192.168.100.11   # Должен пинговаться

# На VM2:
ping 192.168.100.10   # Должен пинговаться
```

---

### 3.4. Порты Kubernetes доступны

- [ ] **Порт 6443 (API) доступен** между VM
- [ ] **Порт 22 (SSH) доступен** между VM

**Как проверить:**
```bash
# На VM1:
nc -zv 192.168.100.11 22     # SSH
nc -zv 192.168.100.11 6443   # Kubernetes API (будет closed, это нормально пока нет K8s)

# Должно вернуть "succeeded" или "connected" (не "filtered" или "no route")
```

---

## РАЗДЕЛ 4: SpoofGuard ⚠️

### 4.1. SpoofGuard настроен

**Выбери один из вариантов:**

**Вариант A: Whitelist создан (рекомендуется для Prod)**
- [ ] **API VIP добавлен** в SpoofGuard Allowed IP Addresses
- [ ] **MetalLB pool добавлен** в SpoofGuard Allowed IP Addresses

**Вариант B: SpoofGuard отключен (проще для PoC)**
- [ ] **SpoofGuard выключен** на сегменте или портах k8s-нод
- [ ] **Задокументировано**, что для Prod нужно включить с whitelist

**Как проверить:**
- NSX UI → Security → SpoofGuard → Switching Profiles → найти профиль для сегмента

---

### 4.2. Gratuitous ARP работает

- [ ] **Можно анонсировать secondary IP** на тестовой VM (ARP не блокируется)

**Как проверить:**
```bash
# На VM1 (192.168.100.10) добавь secondary IP:
sudo ip addr add 192.168.100.100/24 dev ens192

# С VM2 пингани этот IP:
ping 192.168.100.100   # Должен пинговаться

# Проверь ARP-таблицу на VM2:
arp -n | grep 192.168.100.100
# Должен показать MAC-адрес VM1

# Очисти после теста:
sudo ip addr del 192.168.100.100/24 dev ens192
```

**Если не работает:**
- SpoofGuard блокирует → добавь IP в whitelist или отключи SpoofGuard

---

## РАЗДЕЛ 5: MTU 📏

### 5.1. MTU на VM корректный

- [ ] **MTU на VM vNIC** = Overlay MTU - 100 (обычно 1500)

**Как проверить:**
```bash
# На тестовой VM:
ip link show ens192   # (или другое имя интерфейса)

# Вывод:
# 2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc ...
#                                                    ^^^^
# Должно быть 1500 (если overlay 1600)
```

---

### 5.2. MTU проверен end-to-end

- [ ] **Большие пакеты проходят без фрагментации** между VM

**Как проверить:**
```bash
# На VM1 пингануй VM2 с большим пакетом (без фрагментации):
ping -M do -s 1400 192.168.100.11

# Если проходит (0% packet loss) → MTU OK ✅

# Если не проходит:
ping -M do -s 1200 192.168.100.11  # Уменьшай размер пока не пройдёт
ping -M do -s 1000 192.168.100.11

# Если проходит только с -s 1000 или меньше → MTU проблема!
```

---

### 5.3. MTU задокументирован

- [ ] **MTU значения записаны** в `nsx-configs/segments.md`
  - NSX Overlay MTU: `____`
  - VM vNIC MTU: `____`
  - Cilium MTU (рассчитано): `____`

---

## РАЗДЕЛ 6: DNS и NTP ⏰

### 6.1. DNS настроен

- [ ] **DNS servers определены** и задокументированы в `nsx-configs/segments.md`
- [ ] **DNS работает** на тестовых VM (уже проверено в Разделе 2.2)

---

### 6.2. NTP настроен (опционально для PoC, обязательно для Prod)

- [ ] **NTP servers определены** (корпоративные или pool.ntp.org)
- [ ] **Время синхронизировано** на тестовых VM

**Как проверить:**
```bash
# На VM:
timedatectl status

# Вывод должен показать:
# System clock synchronized: yes
# NTP service: active

# Если не синхронизировано:
sudo apt install systemd-timesyncd
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd
```

---

## РАЗДЕЛ 7: Финальная документация 📄

### 7.1. Файл segments.md заполнен

- [ ] **Файл `nsx-configs/segments.md` создан и заполнен**
  - Segment Name
  - Subnet и Gateway
  - IP Allocation Plan
  - MTU values
  - DNS Servers

---

### 7.2. SpoofGuard whitelist задокументирован

- [ ] **Файл `nsx-configs/spoofguard-whitelist.md` создан**
  - API VIP IP
  - MetalLB IP Pool

---

### 7.3. DFW rules экспортированы

- [ ] **DFW правила экспортированы** (или задокументированы)
  - Скриншот или JSON export в `nsx-configs/dfw-rules.json`

---

## РАЗДЕЛ 8: Итоговая проверка 🎉

### 8.1. Чек-лист готовности

Отметь все пункты, которые выполнены:

- [ ] ✅ Segment готов (можно создать VM)
- [ ] ✅ IP connectivity работает (ping gateway, ping между VM)
- [ ] ✅ External connectivity работает (ping 8.8.8.8, DNS, vCenter)
- [ ] ✅ DFW rules настроены (трафик между VM разрешён)
- [ ] ✅ SpoofGuard настроен (gratuitous ARP работает)
- [ ] ✅ MTU проверен (ping -M do -s 1400 работает)
- [ ] ✅ DNS работает (nslookup google.com)
- [ ] ✅ IP-план задокументирован (`nsx-configs/segments.md`)
- [ ] ✅ Все параметры зафиксированы для использования в K8s setup

**Если ВСЕ пункты ✅ → Готов к Этапу 0.2 (VM Preparation)!**

---

## Troubleshooting (если что-то не работает)

### Проблема: Ping gateway не работает

**Причины:**
- Tier-1 Gateway не подключен к сегменту
- Gateway IP неправильно настроен
- VM не получила IP (проверь `ip addr show`)

**Решение:**
- NSX UI → Networking → Segments → проверь Connected Gateway
- NSX UI → Networking → Tier-1 → проверь Interface на сегменте

---

### Проблема: Ping 8.8.8.8 не работает

**Причины:**
- Tier-1 не подключен к Tier-0
- Нет default route
- NAT не настроен (для приватной подсети)
- DFW блокирует egress

**Решение:**
- NSX UI → Networking → Tier-1 → Tier-0 Connectivity = Connected
- NSX UI → Networking → Tier-1 → Routing → добавить 0.0.0.0/0 → Tier-0
- NSX UI → Networking → Tier-1 → NAT → создать SNAT rule
- NSX UI → Security → DFW → добавить Allow k8s-nodes → Any

---

### Проблема: DNS не работает

**Причины:**
- DNS servers не настроены в VM
- DFW блокирует порт 53 (UDP)

**Решение:**
```bash
# Проверь DNS в VM:
cat /etc/resolv.conf   # Должны быть nameserver <IP>

# Если нет, добавь в /etc/netplan/01-netcfg.yaml:
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: true
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Применить:
sudo netplan apply
```

---

### Проблема: Ping между VM не работает

**Причины:**
- DFW блокирует трафик
- Группа k8s-nodes не содержит эти VM
- Правила имеют низкий приоритет (ниже deny-all)

**Решение:**
- NSX UI → Security → DFW → проверь порядок правил (k8s правила должны быть выше)
- NSX UI → Inventory → Groups → k8s-nodes → проверь Members (должны быть обе VM)
- Добавь правило Allow k8s-nodes → k8s-nodes с Priority 1000

---

### Проблема: Secondary IP не пингуется (SpoofGuard блокирует)

**Причины:**
- SpoofGuard включен без whitelist

**Решение:**
- NSX UI → Security → SpoofGuard → добавить Allowed IP Address для secondary IP
- Или отключить SpoofGuard на портах k8s-нод (менее безопасно)

---

### Проблема: Ping -M do -s 1400 не работает (MTU)

**Причины:**
- MTU на VM слишком большой (должен быть < overlay MTU)
- Где-то в цепочке MTU меньше

**Решение:**
```bash
# Уменьши MTU на VM:
sudo ip link set dev ens192 mtu 1500

# Проверь:
ping -M do -s 1400 <IP>

# Если не помогло, попробуй 1450:
sudo ip link set dev ens192 mtu 1450
```

---

## Следующие шаги

После успешной валидации:

1. ✅ **Закрой задачу Этап 0.1** (NSX-T Network Setup) ← **ТЫ ЗДЕСЬ**
2. 🟡 **Переходи к Этапу 0.2** (VM Preparation)
   - Документ: `docs/02-vm-preparation.md`
   - Задача: создать VM-шаблон для k8s-нод

3. Все параметры NSX-T зафиксированы и готовы для использования в Kubernetes!

---

**Поздравляю! NSX-T настроен и проверен! 🎉**

Теперь можно безопасно разворачивать Kubernetes кластер.
