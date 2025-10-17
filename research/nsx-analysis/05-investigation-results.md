# NSX-T Configuration Questionnaire (Опросник)

> **Цель:** Собрать информацию о текущей NSX-T конфигурации для принятия решения.
> **Инструкция:** Изучи NSX UI и заполни ответы. После заполнения скопируй этот файл в `05-investigation-results.md`.

---

## Как заполнять этот опросник

1. **Открой NSX Manager UI** (обычно `https://<nsx-manager-IP>`)
2. Войди с правами администратора или read-only (достаточно для исследования)
3. **Для каждого вопроса** найди информацию в NSX UI (путь указан в вопросе)
4. **Заполни ответ** прямо в этом файле (замени `____` или `[ ]` на свои данные)
5. **После заполнения** скопируй файл: `cp 04-current-config-questionnaire.md 05-investigation-results.md`
6. **AI-агент** проанализирует твои ответы и даст рекомендации

---

## РАЗДЕЛ 1: Общая информация о NSX-T

### 1.1. Версия NSX-T

**Где искать:** NSX UI → System → Settings → Appliances → NSX Manager → Version

**Ответ:**
```
Версия NSX-T: 4.2.3.0.0
```

---

### 1.2. Tier-0 Gateway

**Где искать:** NSX UI → Networking → Tier-0 Gateways

**Вопросы:**
1. Сколько Tier-0 Gateway существует? `1`
2. Имя основного Tier-0: `T0-GW`
3. Тип: `Active-Active` или `Active-Standby`? `Active Standby`
4. Подключен к Edge Cluster? `Да, EC-1`

---

### 1.3. Tier-1 Gateway

**Где искать:** NSX UI → Networking → Tier-1 Gateways

**Вопросы:**
1. Сколько Tier-1 Gateway существует? `7`
2. Перечисли имена всех Tier-1:
   - `domain-c20:982104c6-2855-4af1-8101-3fde7d652df7`
   - `t1-domain-c20:982104c6-2855-4af1-8101-3fde7d652df7-de`
   - `...` (это NSX-T для NCP они автоматом создаются на каждый k8s кластер)
   - `T1-GW-1`
3. К какому Tier-0 они подключены? `все к одному T0-GW`

---

### 1.4. Segments (Сегменты)

**Где искать:** NSX UI → Networking → Segments

**Вопросы:**
1. Сколько всего сегментов существует? `14`
2. Перечисли имена **всех** сегментов (или хотя бы первые 10):
   ```
   - External-segment-1
   - seg-domain-c20:982104c6-2855-4af1-
   - seg-domain-c20:982104c6-2855-4af1-8101
   - VIP-VM
   - vm-domain-c20:982104c6-2855-4af1
   - vnet-domain-c20:982104c6-2855-4af
   - vnet-domain-c20:982104c6-2855-4af1
   ```

3. Какие сегменты используются **Tanzu Supervisor**? (обычно имеют префикс "ncp" или тег "ncp/cluster")
   ```
   - vm-domain-...
   - seg-domain-...
   ```

---

## РАЗДЕЛ 2: Детали сегмента "VIP-VM"

### 2.1. Базовая информация

**Где искать:** NSX UI → Networking → Segments → **VIP-VM** → Overview

**Вопросы:**
1. **Подсеть (CIDR):** `172.16.100.1/24` (например, 192.168.10.0/24)
2. **Gateway IP:** `____________` нет в UI
3. **Connected Gateway (Tier-1):** `T1-GW-1` (имя Tier-1)
4. **Transport Zone:** `nsx-overlay-transportzone | Overlay`
5. **DHCP Config:**
   - DHCP включен? `Да` / `Нет` не знаю, нет информации. Может быть это IP Discovery из SEGMENT PROFILES? Если да, то это профиль default-ip-discovery-profile
   - Если Да, DHCP Range: `____________` (например, 192.168.10.100-200)
   - Если Да, DHCP Options (DNS servers): `____________`

---

### 2.2. Использование IP в сегменте VIP-VM

**Где искать:**
- vCenter → Networking → найти Port Group соответствующий VIP-VM → посмотреть подключенные VM
- Или: NSX UI → Inventory → Virtual Machines → фильтр по Segment "VIP-VM"

**Вопросы:**
1. Сколько **VM подключено** к сегменту VIP-VM? `____`
2. Перечисли имена VM и их IP (если знаешь):
   ```
   VM Name            | IP Address       | Purpose (если знаешь)
   -------------------|------------------|----------------------
   _____________      | ___________      | _______________
   _____________      | ___________      | _______________
   _____________      | ___________      | _______________
   ```

3. Используется ли VIP-VM для **критичных production сервисов**? `На этом роутере сидят виртуальны машины пользователей`
4. Используется ли VIP-VM для **Tanzu Supervisor** или **Tanzu Guest Clusters**? `Нет`

---

### 2.3. Свободные IP в VIP-VM

**Расчёт:**
- Общий размер подсети: `256` IP (например, для /24 это 256)
- Минус Gateway IP: `-1`
- Минус Broadcast: `-1`
- Минус используемые VM: `-96`
- Минус DHCP pool (если включен): `-____`
- **Свободных IP:** `____`

**Достаточно ли IP для Kubernetes?**
Нужно минимум:
- 3 Control Plane: `3 IP`
- 2 Worker (+ запас 3): `5 IP`
- API VIP: `1 IP`
- MetalLB Pool: `20 IP`
- **Итого минимум:** `29 IP`

**Ответ:** `VIP-VM пул это ВМ пользователей и их будет становиться только больше, поэтому нам нужна другая сеть`

---

### 2.4. Tier-1 Gateway для VIP-VM

**Где искать:** NSX UI → Networking → Segments → VIP-VM → Connected Gateway → кликнуть на имя Tier-1

**Вопросы:**
1. Имя Tier-1 для VIP-VM: `T1-GW-1`
2. Tier-1 подключен к Tier-0? `Да`
3. Есть ли Default Route (0.0.0.0/0 → Tier-0)?
   - Где проверить: Tier-1 → Routing → Static Routes
   - Ответ: `не знаю я не вижу этого параметра`

---

## РАЗДЕЛ 3: Distributed Firewall (DFW)

### 3.1. Общая информация

**Где искать:** NSX UI → Security → Distributed Firewall

**Вопросы:**
1. Есть ли **активные DFW правила** (не считая дефолтные)? `Да`
2. Сколько категорий правил существует? `1 ds-domain-c20:982104c6-2855-4af1-8101-3fde7d652df7` (Ethernet, Emergency, Infrastructure, etc.)
3. Есть ли правила категории **Infrastructure** (обычно для критичной инфры)? `Да`
4. Есть ли **default deny rule** (блокирующее правило в конце)? `Есть Default Rule NDP и Default Rule DHCP и Default Layer3 Rule`

---

### 3.2. Groups (Группы для DFW)

**Где искать:** NSX UI → Inventory → Groups

**Вопросы:**
1. Существуют ли группы, связанные с **VIP-VM**? `Да` / `Нет`
   - Если Да, имена: `____________`
2. Существуют ли группы, связанные с **Tanzu**? `Да` / `Нет`
   - Если Да, имена (обычно префикс "ncp"): `____________`

---

### 3.3. DFW правила для VIP-VM (если есть)

**Где искать:** NSX UI → Security → Distributed Firewall → найти правила, где Source/Destination = группа VIP-VM или подсеть

**Вопросы:**
1. Есть ли правила, **ограничивающие трафик** для VIP-VM? `Да` / `Нет` / `Не могу найти`
2. Если Да, какие? (скопируй названия правил или скриншот):
   ```
   Rule Name          | Source         | Destination    | Action
   -------------------|----------------|----------------|--------
   _____________      | ___________    | ___________    | Allow/Drop
   _____________      | ___________    | ___________    | Allow/Drop
   ```

3. Если ты создашь 5 новых VM в VIP-VM, будет ли трафик между ними **заблокирован по умолчанию**?
   - Ответ: `Не уверен`

---

## РАЗДЕЛ 4: SpoofGuard

### 4.1. Статус SpoofGuard

**Где искать:** NSX UI → Security → SpoofGuard

**Вопросы:**
1. SpoofGuard **включен глобально**? `Нет` / `Не могу найти`
2. Режим SpoofGuard:
   - Где проверить: Security → SpoofGuard → Switching Profiles
   - Режим: `Здесь нет такого раздела`

---

### 4.2. SpoofGuard для VIP-VM

**Где искать:** NSX UI → Security → SpoofGuard → Switching Profiles → найти профиль для VIP-VM

**Вопросы:**
1. Какой SpoofGuard профиль применён к сегменту VIP-VM? `____________`
2. Есть ли **Allowed IP Addresses** (whitelist) в этом профиле? `Да` / `Нет`
   - Если Да, какие IP: `____________`
3. Можно ли **редактировать** этот профиль? `Да` / `Нет` / `Не уверен`

**Важно:** Если SpoofGuard включен без whitelist, kube-vip и MetalLB будут **заблокированы**!

---

## РАЗДЕЛ 5: MTU

### 5.1. NSX Overlay MTU

**Где искать:** NSX UI → System → Fabric → Nodes → Transport Nodes → выбрать любой Transport Node → Transport Zones → Overlay

**Вопросы:**
1. **Overlay MTU на Transport Nodes:** `____` (обычно 1600 или 9000)
2. Все Transport Nodes имеют **одинаковый MTU**? `Да` / `Нет`

---

### 5.2. MTU на существующих VM (если можешь проверить)

**Если у тебя есть тестовая VM в VIP-VM или другом сегменте:**

```bash
# Войди на VM по SSH и выполни:
ip link show

# Найди строку вроде:
# 2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc ...
```

**Ответ:**
```
MTU на VM vNIC: 1500 (обычно 1500)
```

---

## РАЗДЕЛ 6: NAT и External Connectivity

### 6.1. NAT правила

**Где искать:** NSX UI → Networking → Tier-1 Gateways → выбрать Tier-1 для VIP-VM → NAT

**Вопросы:**
1. Есть ли **NAT правила** на Tier-1? `Нет`
2. Если Да, тип: `SNAT` / `DNAT` / `Оба`
3. Для каких подсетей настроен SNAT? `____________`

---

### 6.2. Проверка external connectivity (если можешь)

**Если у тебя есть тестовая VM в VIP-VM:**

```bash
# Войди на VM и проверь:
ping 8.8.8.8           # Интернет доступен?
nslookup google.com    # DNS работает?
curl -k https://<vcenter-IP>  # vCenter доступен?
```

**Ответы:**
1. `ping 8.8.8.8`: `Работает`
2. `nslookup google.com`: `Работает`
3. vCenter доступен с VM: `Да`

---

## РАЗДЕЛ 7: DNS Configuration

### 7.1. DNS Servers

**Где искать:** NSX UI → Networking → Segments → VIP-VM → DHCP Config → Options

**Вопросы:**
1. DNS servers настроены в DHCP? `Да` / `Нет` / `DHCP не используется`
2. Если Да, какие DNS: `____________, ____________`
3. Если DHCP не используется, где планируешь настроить DNS для VM?
   - `Вручную в Ubuntu (netplan)` / `Cloud-init` / `Другое: ____________`

---

## РАЗДЕЛ 8: Tanzu Integration

### 8.1. Tanzu IP Pools

**Где искать:** NSX UI → Networking → IP Address Pools

**Вопросы:**
1. Есть ли **IP Pools** для Tanzu? `Да` / `Нет`
2. Если Да, какие диапазоны используются?
   ```
   Pool Name                | IP Range           | Purpose
   -------------------------|--------------------|-----------------
   _____________            | ___________        | Tanzu Pod CIDR
   _____________            | ___________        | Tanzu SNAT
   _____________            | ___________        | Tanzu LB
   ```

**Важно:** Убедись, что **MetalLB pool** (например, 192.168.100.200-220) **НЕ пересекается** с Tanzu pools!

---

### 8.2. Tanzu vs VIP-VM

**Вопросы:**
1. Используется ли сегмент VIP-VM **Tanzu Supervisor** или **Guest Clusters**? `Да` / `Нет` / `Не уверен`
2. Можно ли **безопасно** добавить 5 новых VM в VIP-VM, не нарушив Tanzu? `Да` / `Нет` / `Нужно проверить с командой Tanzu`

---

## РАЗДЕЛ 9: Дополнительные вопросы

### 9.1. Доступы и изменения

**Вопросы:**
1. У тебя есть **права на изменение** NSX конфигурации? `Да` / `Нет` / `Только read-only`
2. Если Нет, кто может помочь с изменениями? `____________` (имя/роль человека)
3. Есть ли **процедура Change Management** для изменений в NSX? `Да` / `Нет`
   - Если Да, нужно ли согласование? `Да` / `Нет`

---

### 9.2. Предпочтения

**Вопросы (твоё мнение):**
1. Ты предпочитаешь **использовать VIP-VM** или **создать новый сегмент k8s-nodes**?
   - `Использовать VIP-VM` / `Создать новый` / `Не уверен, жду рекомендации AI`
2. Почему? (опиши своё видение):
   ```
   ___________________________________________________________
   ___________________________________________________________
   ```

---

## РАЗДЕЛ 10: Скриншоты (опционально, но очень полезно!)

Если можешь, сделай **скриншоты** следующих экранов в NSX UI:

1. **Segments list** (NSX → Networking → Segments)
   - Сохрани как: `research/nsx-analysis/screenshots/01-segments-list.png`

2. **VIP-VM Segment Details** (NSX → Networking → Segments → VIP-VM)
   - Сохрани как: `research/nsx-analysis/screenshots/02-vip-vm-details.png`

3. **DFW Rules** (NSX → Security → Distributed Firewall)
   - Сохрани как: `research/nsx-analysis/screenshots/03-dfw-rules.png`

4. **SpoofGuard** (NSX → Security → SpoofGuard)
   - Сохрани как: `research/nsx-analysis/screenshots/04-spoofguard.png`

5. **Tier-1 Gateway for VIP-VM** (NSX → Networking → Tier-1 Gateways)
   - Сохрани как: `research/nsx-analysis/screenshots/05-tier1-gateway.png`

---

## Что дальше?

После заполнения этого опросника:

1. **Скопируй файл:**
   ```bash
   cp research/nsx-analysis/04-current-config-questionnaire.md \
      research/nsx-analysis/05-investigation-results.md
   ```

2. **Сообщи AI-агенту:**
   "Я заполнил 05-investigation-results.md, можешь проанализировать?"

3. **AI-агент создаст рекомендацию** в `06-decision-analysis.md`

4. **Ты примешь решение** и перейдёшь к настройке NSX

---

**Удачи в исследовании NSX-T! 🔍**

Не стесняйся задавать вопросы, если что-то непонятно в NSX UI — я помогу!
