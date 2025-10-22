# 🎯 Следующие шаги (для оператора)

> **Обновлено:** 2025-10-22
> **Текущий этап:** Этап 0.2 — VM Template Preparation
> **Статус:** 🟡 Готово к передаче AI-агенту

---

## ✅ Что уже сделано

1. ✅ **Контекстный документ** расширен всеми необходимыми параметрами
2. ✅ **Структура репозитория** создана (docs, manifests, scripts, research, etc.)
3. ✅ **Мастер-план проекта** подготовлен (PROJECT-PLAN.md)
4. ✅ **NSX-T Investigation & Setup** полностью завершён ✅
   - ✅ Создан T1 Gateway `T1-k8s-zeon-dev`
   - ✅ Создан сегмент `k8s-zeon-dev-segment` (10.246.10.0/24)
   - ✅ Настроены NAT правила, проведена валидация
   - ✅ Все параметры задокументированы в `nsx-configs/`
5. ✅ **Задача для AI-агента** по VM Template подготовлена

---

## 🚀 Что делать дальше (СЕЙЧАС)

### Шаг 1: Передать задачу AI-агенту по VM Template Preparation

**Цель:** Создать готовый к использованию VM Template Ubuntu 24.04 LTS с предустановленными Kubernetes компонентами.

**Действия:**

1. **Откройте новый чат с AI-агентом** (Cursor, ChatGPT, Claude, или другой)

2. **Прикрепите файлы:**
   - `k8s-on-vsphere-nsx-context.md` (обязательно!)
   - `research/vm-preparation/AI-AGENT-TASK.md` (главная инструкция)
   - `nsx-configs/segments.md` (готовые сетевые параметры)

3. **Скопируйте и отправьте промпт:**

```
Привет! Ты AI-агент, работающий над проектом Kubernetes на vSphere с NSX-T.

Я прикрепил три ключевых документа:
1. k8s-on-vsphere-nsx-context.md — техническое задание проекта
2. research/vm-preparation/AI-AGENT-TASK.md — твоя конкретная задача
3. nsx-configs/segments.md — готовые сетевые параметры (NSX настроен!)

Твоя задача: создать готовый к использованию VM Template Ubuntu 24.04 LTS с предустановленными Kubernetes компонентами.

NSX-T уже настроен ✅:
- Segment: k8s-zeon-dev-segment (10.246.10.0/24)
- Control Plane IPs: 10.246.10.10-12
- Worker IPs: 10.246.10.20-30
- API VIP: 10.246.10.100

Важно проверить доступность Kubernetes 1.34.x — возможно нужна более стабильная версия.

Пожалуйста:
1. Внимательно прочитай AI-AGENT-TASK.md
2. Начни с Этапа 1 (Анализ версий и требований)
3. Создавай артефакты последовательно (01, 02, 03, ...)
4. Пиши готовые к использованию скрипты (без TODO)

Все артефакты сохраняй в папку research/vm-preparation/ согласно инструкции.

Готов начать? Давай стартуем с анализа версий компонентов!
```

4. **Работайте с AI-агентом итеративно:**
   - Он будет создавать документы (01-version-analysis.md, 02-template-strategy.md, ...)
   - Вы копируете содержимое и сохраняете в `research/vm-preparation/`
   - Он создаст готовые к использованию скрипты в `scripts/`
   - Он создаст cloud-init конфигурации в `vm-templates/`
   - Следуйте инструкциям для создания VM Template в vSphere

5. **Создайте VM Template:**
   - Создайте базовую VM в vSphere (подключение к `k8s-zeon-dev-segment`)
   - Выполните скрипт подготовки (`scripts/prepare-vm.sh`)
   - Создайте VM Template в vSphere
   - Протестируйте первое клонирование с cloud-init

6. **Валидация:**
   - Убедитесь что клонированная VM получает правильный IP
   - Проверьте что все K8s компоненты установлены
   - Готовность к `kubeadm init`

---

### Шаг 2: После завершения VM Template

**Когда:** После того как VM Template создан и протестирован

**Действия:**
1. Обновите `PROJECT-PLAN.md` (отметьте выполненные пункты Этапа 0.2)
2. Обновите `NEXT-STEPS.md` (этот файл) с новыми инструкциями
3. Переходите к **Этапу 1.1: Cluster Bootstrap** (`docs/03-cluster-bootstrap.md`)

---

## 📋 Чек-лист текущей задачи (VM Template Preparation)

Отмечайте по мере выполнения:

- [ ] Открыл новый чат с AI-агентом
- [ ] Прикрепил `k8s-on-vsphere-nsx-context.md`
- [ ] Прикрепил `research/vm-preparation/AI-AGENT-TASK.md`
- [ ] Прикрепил `nsx-configs/segments.md`
- [ ] Отправил промпт
- [ ] Получил анализ версий компонентов (01-version-analysis.md)
- [ ] Получил стратегию Template (02-template-strategy.md)
- [ ] Получил инструкции создания базовой VM (03-base-vm-creation.md)
- [ ] Получил инструкции установки K8s (04-k8s-installation.md)
- [ ] Получил инструкции финализации (05-template-finalization.md)
- [ ] Получил готовые скрипты (`scripts/prepare-vm.sh`, validate, cleanup)
- [ ] Получил cloud-init конфигурации (`vm-templates/`)
- [ ] Создал базовую VM в vSphere (подключил к `k8s-zeon-dev-segment`)
- [ ] Выполнил скрипт подготовки VM
- [ ] Создал VM Template в vSphere
- [ ] Протестировал первое клонирование с cloud-init
- [ ] Обновил `PROJECT-PLAN.md` (отметил Этап 0.2 завершённым)

---

## 💡 Полезные ссылки

**Основные документы:**
- [README.md](./README.md) — обзор проекта
- [k8s-on-vsphere-nsx-context.md](./k8s-on-vsphere-nsx-context.md) — источник правды
- [PROJECT-PLAN.md](./PROJECT-PLAN.md) — мастер-план
- [HOW-TO-DELEGATE-TO-AI.md](./HOW-TO-DELEGATE-TO-AI.md) — инструкция по работе с AI

**Завершённые задачи:**
- ✅ [research/nsx-analysis/AI-AGENT-TASK.md](./research/nsx-analysis/AI-AGENT-TASK.md) — NSX-T настройка (завершена)
- ✅ [docs/01-nsx-network-setup.md](./docs/01-nsx-network-setup.md) — NSX setup (завершён)

**Текущая задача:**
- [research/vm-preparation/AI-AGENT-TASK.md](./research/vm-preparation/AI-AGENT-TASK.md) — детальная задача для AI-агента
- [docs/02-vm-preparation.md](./docs/02-vm-preparation.md) — обзор VM Template preparation

**Troubleshooting:**
- [docs/99-troubleshooting.md](./docs/99-troubleshooting.md) — решение проблем

---

## ❓ Вопросы?

Если что-то непонятно:
1. Перечитайте [HOW-TO-DELEGATE-TO-AI.md](./HOW-TO-DELEGATE-TO-AI.md)
2. Проверьте [k8s-on-vsphere-nsx-context.md](./k8s-on-vsphere-nsx-context.md) (раздел 10 — Риски)
3. Создайте файл `research/nsx-analysis/QUESTIONS-FOR-TEAM-LEAD.md` с вопросами

---

## 🎉 После завершения NSX setup

Поздравляю! Вы завершите первый критический этап.

**Следующим будет:** Подготовка VM-шаблонов (Ubuntu 24.04 + Kubernetes 1.34)

Этот файл будет обновлён с новыми инструкциями после завершения текущего этапа.

---

**Удачи! 🚀**
