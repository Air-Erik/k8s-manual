# 🚀 Начало работы: NSX-T Investigation

> **Для оператора:** Прочитай этот документ, чтобы понять, с чего начать!

---

## Что было сделано? ✅

**AI-агент завершил Этап 1** и подготовил все необходимые материалы:

### Образовательные материалы (изучи в первую очередь!)

1. **[01-nsx-basics-for-k8s.md](./01-nsx-basics-for-k8s.md)** (~10 минут)
   - Основы NSX-T: Tier-0/1, Segments, DFW, SpoofGuard, MTU
   - Что это значит для Kubernetes

2. **[02-tanzu-vs-standalone-k8s.md](./02-tanzu-vs-standalone-k8s.md)** (~8 минут)
   - Разница между Tanzu и standalone K8s на NSX
   - Почему они могут работать параллельно

3. **[03-k8s-network-requirements.md](./03-k8s-network-requirements.md)** (~10 минут)
   - Полный чек-лист: что нужно от NSX-T для нашего кластера
   - Segment, IP-план, DFW, SpoofGuard, MTU, DNS

**Время на изучение: ~30 минут** ☕

---

## Что нужно сделать ТЕБЕ? 📋

### Шаг 1: Изучить материалы (30 минут)

Прочитай документы 01-03 (см. выше). Это даст тебе базовое понимание NSX-T.

**Если есть вопросы:**
- Записывай их в [QUESTIONS-FOR-OPERATOR.md](./QUESTIONS-FOR-OPERATOR.md)
- AI-агент ответит!

---

### Шаг 2: Исследовать NSX-T (1-2 часа)

**Что делать:**

1. Открой **NSX Manager UI** (https://<your-nsx-manager>)
2. Открой файл **[04-current-config-questionnaire.md](./04-current-config-questionnaire.md)**
3. **Заполни все ответы**, изучая NSX UI (в опроснике указаны точные пути: Networking → Segments, etc.)

**Что искать:**
- Сколько Tier-0/Tier-1 Gateway?
- Какие сегменты существуют?
- Детали сегмента **VIP-VM** (подсеть, gateway, DHCP, Tier-1)
- Сколько VM уже в VIP-VM?
- DFW правила (блокируют ли трафик?)
- SpoofGuard включен?
- MTU на Transport Nodes

---

### Шаг 3: Сохранить результаты

После заполнения опросника:

```bash
# В корне репозитория:
cp research/nsx-analysis/04-current-config-questionnaire.md \
   research/nsx-analysis/05-investigation-results.md
```

**Опционально (но полезно!):**
- Сделай скриншоты NSX UI (см. `screenshots/README.md`)

---

### Шаг 4: Сообщить AI-агенту

Напиши AI-агенту:

> "Я заполнил `05-investigation-results.md`, можешь проанализировать?"

**AI-агент сделает:**
1. Проанализирует твои ответы
2. Создаст рекомендацию: использовать VIP-VM или создать новый сегмент
3. Создаст пошаговые инструкции для настройки NSX-T

---

### Шаг 5: Применить инструкции (после получения от AI)

AI-агент создаст один из файлов:
- `07-setup-instructions-vip-vm.md` (если используем VIP-VM)
- `08-setup-instructions-new-segment.md` (если создаём новый сегмент)

**Ты применишь инструкции** в NSX UI (создание групп, DFW rules, SpoofGuard whitelist, etc.)

---

### Шаг 6: Валидация

После настройки NSX:
1. Создай 1-2 **тестовые VM** в сегменте k8s-nodes (или VIP-VM)
2. Пройди **все тесты** из [09-validation-checklist.md](./09-validation-checklist.md)
3. Заполни финальные параметры в `nsx-configs/segments.md`

**Если все тесты ✅ → NSX-T готов для Kubernetes!**

---

## Roadmap (что дальше после NSX-T)

```
Этап 0.1: NSX-T Setup       ← ТЫ ЗДЕСЬ (на Шаге 1)
    ↓
Этап 0.2: VM Preparation    ← Следующий (создание VM-шаблонов для k8s-нод)
    ↓
Этап 1.1: Cluster Bootstrap ← kubeadm init, kube-vip, join nodes
    ↓
Этап 1.2: CNI Setup         ← Cilium installation
    ↓
Этап 1.3: Storage Setup     ← vSphere CSI Driver
    ↓
Этап 1.4: MetalLB Setup     ← LoadBalancer IP pool
    ↓
Этап 1.5: Ingress Setup     ← NGINX Ingress Controller
    ↓
Готово! Kubernetes работает! 🎉
```

---

## Краткая справка

### Файлы для изучения (ЧИТАЙ!)
- `01-nsx-basics-for-k8s.md` — основы NSX-T
- `02-tanzu-vs-standalone-k8s.md` — Tanzu vs standalone
- `03-k8s-network-requirements.md` — что нужно от NSX

### Файлы для заполнения (ЗАПОЛНЯЙ!)
- `04-current-config-questionnaire.md` → копировать в `05-investigation-results.md`

### Файлы для применения (ПОЗЖЕ!)
- `07-setup-instructions-vip-vm.md` ИЛИ `08-setup-instructions-new-segment.md` (AI-агент создаст)

### Файлы для валидации (ПОСЛЕ НАСТРОЙКИ!)
- `09-validation-checklist.md` — проверить, что всё работает

### Финальные конфиги (ЗАПОЛНИШЬ В КОНЦЕ!)
- `nsx-configs/segments.md` — итоговые параметры сети
- `nsx-configs/spoofguard-whitelist.md` — whitelist для VIP и MetalLB

---

## Полезные ссылки

- **Полный план проекта:** [PROJECT-PLAN.md](../../PROJECT-PLAN.md)
- **Контекст проекта:** [k8s-on-vsphere-nsx-context.md](../../k8s-on-vsphere-nsx-context.md)
- **README этой директории:** [README.md](./README.md)

---

## Помощь

### Если что-то непонятно:
1. Записывай вопросы в [QUESTIONS-FOR-OPERATOR.md](./QUESTIONS-FOR-OPERATOR.md)
2. AI-агент ответит и обновит документ

### Если не можешь найти что-то в NSX UI:
1. Используй поиск в NSX UI (верхний правый угол)
2. Или спроси AI-агента: "Где найти X в NSX UI?"

### Если застрял:
1. Опиши проблему AI-агенту
2. Приложи скриншот (если возможно)
3. AI-агент поможет разобраться

---

## Мотивация 💪

**Ты делаешь важную работу!**

NSX-T — это сложная штука, но после изучения материалов ты будешь понимать:
- Как работает сеть в vSphere/NSX
- Почему Kubernetes требует определённых настроек
- Как Tanzu и standalone K8s могут сосуществовать

Это знание **пригодится в карьере** — NSX-T используется во многих enterprise-средах.

**Главное правило:** Не спеши, читай внимательно, задавай вопросы. AI-агент здесь, чтобы помочь! 🤖

---

## Чек-лист для старта

Перед тем, как начать, убедись:

- [ ] ✅ У тебя есть доступ к **NSX Manager UI** (хотя бы read-only для исследования)
- [ ] ✅ У тебя есть **~2 часа свободного времени** (30 минут на чтение + 1-2 часа на исследование)
- [ ] ✅ Ты готов **изучать новое** (NSX-T может показаться сложным, но документы написаны просто!)
- [ ] ✅ У тебя есть **где записывать заметки** (можешь прямо в опроснике)

**Готов? Поехали! 🚀**

---

## Следующий шаг

👉 **Открой [01-nsx-basics-for-k8s.md](./01-nsx-basics-for-k8s.md) и начинай читать!**

После прочтения всех трёх документов (01-03) переходи к заполнению опросника (04).

**Удачи! Ты справишься! 💪**
