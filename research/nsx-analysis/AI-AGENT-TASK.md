# Задание для AI-агента: NSX-T Network Investigation & Setup

> **Тип задачи:** Исследование + Обучение + Настройка
> **Приоритет:** 🔴 КРИТИЧЕСКИЙ (блокирует весь проект)
> **Время:** Не ограничено (важнее качество, чем скорость)
> **Оператор:** Человек с минимальными знаниями NSX-T

---

## Контекст

**Ситуация:**
- NSX-T 4.2.3 развернут **не оператором**, настраивался под Tanzu Supervisor
- Оператор имеет **минимальные знания NSX-T** (только поверхностные концепции)
- Существует сегмент **"VIP-VM"** — неясно, можно ли его использовать для Kubernetes нод
- Нужно принять решение: использовать существующий сегмент или создать новый

**Цель проекта:**
Развернуть самостоятельный Kubernetes кластер на VM с NSX-T как underlay-сетью (без NCP).

**Твоя роль как AI-агента:**
Ты — **наставник и технический консультант**. Твоя задача:
1. **Обучить** оператора основам NSX-T (без перегруза информацией)
2. **Помочь исследовать** текущую конфигурацию NSX-T
3. **Дать рекомендации** по использованию существующей сети или созданию новой
4. **Создать пошаговые инструкции** для настройки NSX под нужды Kubernetes

---

## Структура задания

### Этап 1: Образовательная часть ⭐ НАЧАТЬ С ЭТОГО
### Этап 2: Исследование текущей конфигурации
### Этап 3: Анализ и принятие решений
### Этап 4: Создание инструкций по настройке
### Этап 5: Валидация и документация

---

## ЭТАП 1: Образовательная часть (NSX-T для Kubernetes)

**Твоя задача:** Создать краткий, но информативный образовательный материал.

### Что нужно объяснить:

#### 1.1. Основы NSX-T (концепции для Kubernetes)
Создай документ `research/nsx-analysis/01-nsx-basics-for-k8s.md` с объяснением:

**Обязательные темы:**
- Что такое NSX-T и зачем он нужен в vSphere
- Архитектура NSX-T: Transport Zones, Edge Nodes, Transport Nodes
- **Tier-0 Gateway** (North-South routing) — что это и когда используется
- **Tier-1 Gateway** (East-West + NAT) — что это и для чего
- **Segments** (логические сети L2) — как это работает, привязка к Tier-1
- **Distributed Firewall (DFW)** — базовые концепции, группы, правила
- **SpoofGuard** — что это, почему может блокировать VIP/ARP, как работает
- **IPAM/DHCP** в NSX-T — можно ли использовать для VM
- **MTU** в NSX overlay — почему это важно для Kubernetes

**Формат:**
- Без воды, только суть
- Диаграммы приветствуются (ASCII art или описание для рисования)
- Примеры для Kubernetes use-case
- **НЕ БОЛЕЕ 3-4 страниц** (чтобы не перегрузить оператора)

**Важные акценты для Kubernetes:**
- Как NSX предоставляет сеть для VM (нод кластера)
- Почему NSX НЕ должен управлять Pod-сетью (это делает CNI)
- Почему важно разрешить gratuitous ARP для kube-vip и MetalLB
- Какие порты нужно открыть между нодами

---

#### 1.2. Tanzu vs Standalone Kubernetes на NSX
Создай документ `research/nsx-analysis/02-tanzu-vs-standalone-k8s.md`:

**Объясни:**
- Как Tanzu Supervisor использует NSX (NCP integration, automatic network provisioning)
- Почему мы **НЕ используем** NCP в нашем случае
- В чём разница между "NSX as CNI" (NCP) и "NSX as underlay" (наш случай)
- Можно ли использовать один NSX для Tanzu и Standalone k8s (ответ: да, через разные сегменты)

---

#### 1.3. Чек-лист сетевых требований для Kubernetes
Создай документ `research/nsx-analysis/03-k8s-network-requirements.md`:

**Что нужно от NSX для нашего кластера:**
- [ ] L2 Segment для VM (с IP-подсетью)
- [ ] Gateway для внешнего доступа (Tier-1 → Tier-0)
- [ ] Диапазон IP для нод (статические или DHCP)
- [ ] Зарезервированный IP для API VIP (kube-vip)
- [ ] Диапазон IP для MetalLB (LoadBalancer Services)
- [ ] DFW правила: разрешить inter-node трафик, NodePort, egress
- [ ] SpoofGuard: whitelist для VIP и MetalLB IP
- [ ] MTU: согласованность с NSX overlay
- [ ] NAT (опционально): если нужен egress для Pods/Nodes

**Порты, которые нужно разрешить между нодами:**
- TCP 6443 (Kubernetes API)
- TCP 2379-2380 (etcd)
- TCP 10250 (kubelet)
- TCP/UDP 8472 (Cilium VXLAN, если используется)
- TCP 4240 (Cilium Health Check)
- TCP 30000-32767 (NodePort Services)

---

### Артефакты Этапа 1:
- [ ] `research/nsx-analysis/01-nsx-basics-for-k8s.md`
- [ ] `research/nsx-analysis/02-tanzu-vs-standalone-k8s.md`
- [ ] `research/nsx-analysis/03-k8s-network-requirements.md`

---

## ЭТАП 2: Исследование текущей конфигурации

**Твоя задача:** Создать опросник/чек-лист для оператора, чтобы собрать информацию о текущей NSX-T.

### Что нужно узнать:

Создай документ `research/nsx-analysis/04-current-config-questionnaire.md`:

#### 2.1. Общая информация
**Вопросы оператору:**
1. Сколько Tier-0 Gateway существует?
2. Сколько Tier-1 Gateway существует? Есть ли свободные/доступные?
3. К какому Tier-1 подключен сегмент **VIP-VM**?
4. Какие ещё сегменты существуют? (список имён)
5. Какие сегменты используются Tanzu Supervisor?

#### 2.2. Сегмент "VIP-VM"
**Что проверить в NSX UI → Networking → Segments → VIP-VM:**
- Подсеть (CIDR): `___________`
- Gateway IP: `___________`
- DHCP enabled?: Да / Нет
- DHCP Range (если да): `___________`
- Связан с Tier-1: `___________`
- Transport Zone: `___________`

**Вопросы для анализа:**
1. Сколько VM уже подключено к VIP-VM? (проверить в vCenter)
2. Какие IP уже используются в этом сегменте?
3. Достаточно ли свободных IP для:
   - 3 Control Plane нод
   - 2+ Worker нод
   - 1 API VIP
   - 10-20 IP для MetalLB pool
4. Используется ли VIP-VM для критичных сервисов?

#### 2.3. Distributed Firewall (DFW)
**Что проверить в NSX UI → Security → Distributed Firewall:**
- Есть ли правила, ограничивающие трафик между VM?
- Есть ли группы (Groups) для VIP-VM сегмента?
- Есть ли default deny rules?

**Вопрос:** Если мы добавим 5 новых VM в VIP-VM (или создадим новый сегмент), будет ли трафик между ними заблокирован?

#### 2.4. SpoofGuard
**Что проверить в NSX UI → Security → SpoofGuard:**
- Включен ли SpoofGuard на VIP-VM сегменте (или глобально)?
- Режим: Port-level или Segment-level?
- Есть ли whitelist'ы для IP?

**Критично:** SpoofGuard может блокировать kube-vip и MetalLB ARP!

#### 2.5. MTU
**Что проверить:**
- NSX Transport Node Overlay MTU: проверить в NSX UI → System → Fabric → Nodes → Transport Nodes
- Обычное значение: 1600 или 9000

**Вопрос:** Какой MTU на overlay? `___________`

#### 2.6. NAT и External Connectivity
**Вопросы:**
1. Есть ли NAT правила на Tier-0 или Tier-1 для VIP-VM сегмента?
2. Могут ли VM в VIP-VM достучаться до:
   - Интернета (для apt, container registry)?
   - Корпоративных DNS серверов?
   - vCenter API (для vSphere CSI)?

---

### Артефакты Этапа 2:
- [ ] `research/nsx-analysis/04-current-config-questionnaire.md` (опросник)
- [ ] `research/nsx-analysis/05-investigation-results.md` (заполненные ответы оператора)

**Инструкция оператору:**
> Скопируй `04-current-config-questionnaire.md` → `05-investigation-results.md` и заполни ответы, исследуя NSX UI.

---

## ЭТАП 3: Анализ и принятие решений

**Твоя задача:** На основе собранных данных дать рекомендацию.

Создай документ `research/nsx-analysis/06-decision-analysis.md`:

### 3.1. Анализ: Использовать VIP-VM или создать новый сегмент?

**Критерии ДЛЯ использования VIP-VM:**
- ✅ Достаточно свободных IP (минимум 30-40 для роста)
- ✅ Сегмент не используется критичными production сервисами
- ✅ Tier-1 Gateway имеет uplink к Tier-0 (внешняя связность)
- ✅ MTU приемлемый (1500 для VM будет достаточно)
- ✅ DFW не блокирует трафик (или можем добавить правила)
- ✅ SpoofGuard можно настроить (whitelist или отключить на порты)

**Критерии ПРОТИВ использования VIP-VM (создать новый сегмент):**
- ❌ Мало свободных IP
- ❌ Сегмент используется Tanzu или критичными сервисами
- ❌ Политики безопасности запрещают смешивание workloads
- ❌ DFW жёстко ограничивает трафик и нельзя изменить
- ❌ Оператор хочет чистое разделение для безопасности

### 3.2. Рекомендация

**На основе ответов из Этапа 2, AI-агент должен:**

1. **Проанализировать** все данные
2. **Выдать рекомендацию:** "Использовать VIP-VM" ИЛИ "Создать новый сегмент k8s-nodes"
3. **Обосновать** решение (плюсы/минусы)
4. **Предупредить о рисках** каждого варианта

**Формат:**
```markdown
## РЕКОМЕНДАЦИЯ: [Использовать VIP-VM / Создать k8s-nodes]

### Обоснование:
- ...
- ...

### Риски:
- ...

### Альтернатива (если передумаем):
- ...
```

---

### Артефакты Этапа 3:
- [ ] `research/nsx-analysis/06-decision-analysis.md` (рекомендация с обоснованием)

---

## ЭТАП 4: Создание инструкций по настройке

**Твоя задача:** Создать подробные, пошаговые инструкции для оператора.

### Вариант A: Если используем VIP-VM

Создай документ `research/nsx-analysis/07-setup-instructions-vip-vm.md`:

**Шаги:**
1. **IP-планирование:**
   - Зарезервировать IP для нод (вручную в табличке или DHCP reservations)
   - Выбрать API VIP IP
   - Выбрать MetalLB IP Pool

2. **DFW Configuration:**
   - Создать группу `k8s-nodes` (по IP или VM tags)
   - Создать правила (с приоритетом выше deny-all):
     - Allow: k8s-nodes → k8s-nodes (любые порты или конкретные)
     - Allow: Any → k8s-nodes (NodePort 30000-32767, 80, 443)
     - Allow: k8s-nodes → Internet/Corp

3. **SpoofGuard Configuration:**
   - Добавить API VIP в whitelist
   - Добавить MetalLB IP Pool в whitelist
   - Или отключить SpoofGuard на портах k8s-нод (менее безопасно)

4. **MTU Verification:**
   - Проверить MTU на Transport Node overlay
   - Задокументировать для настройки Cilium

5. **NAT/Routing Verification:**
   - Убедиться что VM могут достучаться до Internet
   - Проверить DNS resolution

**Формат:** Скриншоты или детальные описания кликов в NSX UI.

---

### Вариант B: Если создаём новый сегмент k8s-nodes

Создай документ `research/nsx-analysis/08-setup-instructions-new-segment.md`:

**Шаги:**
1. **Создание нового сегмента:**
   - Имя: `k8s-nodes-segment`
   - Подсеть: выбрать свободную (например, 192.168.50.0/24)
   - Gateway: .1 (например, 192.168.50.1)
   - DHCP: опционально (или статические IP)
   - Связать с Tier-1 Gateway (тем же или создать новый)

2. **IP-планирование:** (аналогично варианту A)

3. **DFW Configuration:** (аналогично варианту A)

4. **SpoofGuard Configuration:** (аналогично варианту A)

5. **MTU Verification:** (аналогично варианту A)

6. **Routing/NAT Configuration:**
   - Убедиться что Tier-1 подключен к Tier-0
   - Настроить NAT (если нужен SNAT для egress)
   - Advertise routes (если используется BGP на Tier-0)

**Формат:** Скриншоты или детальные описания кликов в NSX UI.

---

### Артефакты Этапа 4:
- [ ] `research/nsx-analysis/07-setup-instructions-vip-vm.md` (если используем VIP-VM)
- [ ] `research/nsx-analysis/08-setup-instructions-new-segment.md` (если новый сегмент)
- [ ] Скриншоты NSX UI с аннотациями (сохранить в `research/nsx-analysis/screenshots/`)

---

## ЭТАП 5: Валидация и финальная документация

**Твоя задача:** Создать чек-лист для проверки после применения настроек.

Создай документ `research/nsx-analysis/09-validation-checklist.md`:

### 5.1. Чек-лист проверки NSX конфигурации

**После применения инструкций из Этапа 4, оператор должен проверить:**

- [ ] **Segment доступен:** Можно выбрать сегмент при создании VM в vSphere
- [ ] **IP connectivity:** Создать тестовую VM в сегменте, пингануть gateway
- [ ] **DFW rules работают:** Создать 2 тестовые VM, проверить ping/ssh между ними
- [ ] **SpoofGuard не блокирует:** На тестовой VM настроить secondary IP, убедиться что ARP работает
- [ ] **External connectivity:** С тестовой VM пингануть Internet (8.8.8.8), резолвить DNS
- [ ] **MTU проверен:** `ip link show` на VM, `ping -M do -s 1400 <gateway>`
- [ ] **Достаточно IP:** Убедиться что можем выделить IP для всех нод + VIP + MetalLB

### 5.2. Финальные параметры для документации

**После валидации, занести в `nsx-configs/segments.md`:**

```markdown
# NSX-T Segment Configuration for Kubernetes

## Segment Information
- **Name:** VIP-VM (или k8s-nodes-segment)
- **Subnet:** 192.168.X.0/24
- **Gateway:** 192.168.X.1
- **DHCP:** Enabled/Disabled
- **Tier-1 Gateway:** <имя>
- **Transport Zone:** <имя>

## IP Allocation Plan
- **VM Nodes:** 192.168.X.10 - 192.168.X.30 (зарезервировано)
- **API VIP:** 192.168.X.100
- **MetalLB Pool:** 192.168.X.200 - 192.168.X.220

## MTU
- **NSX Overlay MTU:** 1600
- **VM vNIC MTU:** 1500
- **Cilium CNI MTU:** 1450 (рекомендуется)

## DNS Servers
- Primary: <IP>
- Secondary: <IP>

## DFW Rules
- Group `k8s-nodes` created: Yes
- Rules priority: 1000 (выше default deny)
- See `nsx-configs/dfw-rules.json` for export

## SpoofGuard
- Mode: Port-level / Segment-level
- Whitelist: API VIP + MetalLB Pool
- See `nsx-configs/spoofguard-whitelist.md`
```

---

### Артефакты Этапа 5:
- [ ] `research/nsx-analysis/09-validation-checklist.md`
- [ ] `nsx-configs/segments.md` (финальная конфигурация)
- [ ] `nsx-configs/spoofguard-whitelist.md` (список whitelist IP)
- [ ] `nsx-configs/dfw-rules.json` (экспорт DFW правил из NSX UI)

---

## Финальный чек-лист для AI-агента

### Обязательные артефакты:

**Образовательные материалы:**
- [ ] `01-nsx-basics-for-k8s.md`
- [ ] `02-tanzu-vs-standalone-k8s.md`
- [ ] `03-k8s-network-requirements.md`

**Исследование:**
- [ ] `04-current-config-questionnaire.md`
- [ ] `05-investigation-results.md` (заполняет оператор)

**Анализ:**
- [ ] `06-decision-analysis.md` (рекомендация)

**Инструкции:**
- [ ] `07-setup-instructions-vip-vm.md` ИЛИ `08-setup-instructions-new-segment.md`
- [ ] Скриншоты NSX UI (если возможно)

**Валидация:**
- [ ] `09-validation-checklist.md`

**Финальная документация (оператор заполняет после настройки):**
- [ ] `../../nsx-configs/segments.md`
- [ ] `../../nsx-configs/spoofguard-whitelist.md`
- [ ] `../../nsx-configs/dfw-rules.json` (экспорт)

---

## Стиль и подход

### Как писать документацию:

✅ **Делай:**
- Пиши просто и понятно (как для junior-специалиста)
- Используй диаграммы и таблицы
- Приводи конкретные примеры
- Объясняй "почему", а не только "что"
- Давай альтернативы (если есть несколько способов)
- Предупреждай о рисках и подводных камнях

❌ **Не делай:**
- Не перегружай информацией (фокус на Kubernetes use-case)
- Не используй сложный жаргон без объяснения
- Не предполагай, что оператор знает NSX (объясняй основы)
- Не пропускай шаги ("это очевидно" — нет, не очевидно)

### Тон общения:
- Дружелюбный наставник, а не строгий профессор
- "Давай разберёмся вместе" вместо "ты должен знать"
- Поддерживающий, а не осуждающий

---

## Вопросы для уточнения (если нужно)

Если в процессе работы тебе (AI-агенту) нужна дополнительная информация от оператора:

1. Создай файл `research/nsx-analysis/QUESTIONS-FOR-OPERATOR.md`
2. Запиши вопросы с контекстом (почему это важно)
3. Оператор ответит, и ты продолжишь работу

---

## Успех задания

Задание считается успешно выполненным, когда:

✅ Оператор **понимает** основы NSX-T (после прочтения образовательных материалов)
✅ Оператор **исследовал** текущую конфигурацию NSX (заполнен questionnaire)
✅ **Принято решение** использовать VIP-VM или создать новый сегмент
✅ **Созданы пошаговые инструкции** для настройки NSX
✅ Оператор **применил** инструкции (или готов применить)
✅ **Валидация пройдена** (тестовые VM работают, connectivity OK)
✅ **Задокументированы финальные параметры** для использования в Kubernetes setup

---

## Координация

После завершения этого задания:
1. Оператор получит все необходимые параметры (subnet, VIP, MetalLB pool, MTU)
2. Параметры будут зафиксированы в `nsx-configs/segments.md`
3. Team Lead обновит `docs/01-nsx-network-setup.md` ссылкой на финальную конфигурацию
4. Проект перейдёт к **Этапу 0.2: VM Preparation**

---

**Удачи, AI-агент! Помни: твоя цель — не просто настроить NSX, а научить оператора понимать, что и зачем он делает.**

🚀 **Начинай с Этапа 1 (Образовательная часть)!**
