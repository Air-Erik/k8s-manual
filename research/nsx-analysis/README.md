# NSX-T Network Investigation & Setup

> **Статус:** 🟡 В процессе (Этап 1 завершён, ожидается заполнение опросника)
> **AI-агент:** Готов к следующим этапам
> **Оператор:** Изучает образовательные материалы

---

## Обзор

Эта директория содержит **все материалы** для исследования и настройки NSX-T под Kubernetes кластер.

**Задача из:** [AI-AGENT-TASK.md](./AI-AGENT-TASK.md)

---

## Структура документов (в порядке чтения)

### 📚 Этап 1: Образовательная часть (COMPLETED ✅)

**Цель:** Понять основы NSX-T для Kubernetes.

1. **[01-nsx-basics-for-k8s.md](./01-nsx-basics-for-k8s.md)**
   - Что такое NSX-T, компоненты (Tier-0/1, Segments, DFW, SpoofGuard, MTU)
   - Как это связано с Kubernetes
   - ~10 минут чтения

2. **[02-tanzu-vs-standalone-k8s.md](./02-tanzu-vs-standalone-k8s.md)**
   - Различия между Tanzu (NSX as CNI) и Standalone K8s (NSX as underlay)
   - Как они могут сосуществовать
   - ~8 минут чтения

3. **[03-k8s-network-requirements.md](./03-k8s-network-requirements.md)**
   - Полный чек-лист: что нужно от NSX-T для Kubernetes
   - Segment, IP-план, DFW, SpoofGuard, MTU, DNS
   - ~10 минут чтения

**Действие оператора:**
- ✅ Прочитать все три документа (займёт ~30 минут)
- ✅ Записать вопросы в [QUESTIONS-FOR-OPERATOR.md](./QUESTIONS-FOR-OPERATOR.md)

---

### 🔍 Этап 2: Исследование (TODO — следующий шаг)

**Цель:** Собрать информацию о текущей NSX-T конфигурации.

4. **[04-current-config-questionnaire.md](./04-current-config-questionnaire.md)**
   - Опросник для заполнения (изучая NSX UI)
   - Вопросы о Tier-0/1, Segments, VIP-VM, DFW, SpoofGuard, MTU

**Действие оператора:**
- 🔲 Открыть NSX Manager UI
- 🔲 Заполнить все ответы в опроснике
- 🔲 Скопировать файл: `cp 04-current-config-questionnaire.md 05-investigation-results.md`
- 🔲 Сообщить AI-агенту: "Я заполнил 05-investigation-results.md"

---

### 🧠 Этап 3: Анализ (AI-агент выполнит)

**Цель:** На основе собранных данных дать рекомендацию.

6. **[06-decision-analysis.md](./06-decision-analysis.md)** (будет создан AI-агентом)
   - Анализ: использовать VIP-VM или создать новый сегмент?
   - Обоснование, риски, альтернативы

**Действие оператора:**
- 🔲 Прочитать рекомендацию AI-агента
- 🔲 Принять решение: VIP-VM или k8s-nodes-segment

---

### 🛠️ Этап 4: Настройка (AI-агент создаст инструкции)

**Цель:** Пошаговые инструкции для настройки NSX-T.

7. **[07-setup-instructions-vip-vm.md](./07-setup-instructions-vip-vm.md)** ИЛИ
8. **[08-setup-instructions-new-segment.md](./08-setup-instructions-new-segment.md)**
   - Детальные шаги для NSX UI (в зависимости от решения)
   - IP-планирование, DFW, SpoofGuard, MTU

**Действие оператора:**
- 🔲 Применить инструкции в NSX UI
- 🔲 Создать/настроить segment, DFW rules, SpoofGuard whitelist

---

### ✅ Этап 5: Валидация (после настройки)

**Цель:** Проверить, что всё работает корректно.

9. **[09-validation-checklist.md](./09-validation-checklist.md)**
   - Чек-лист проверок (connectivity, MTU, DFW, SpoofGuard)
   - Тесты с тестовыми VM

**Действие оператора:**
- 🔲 Создать 1-2 тестовые VM в настроенном сегменте
- 🔲 Пройти все тесты из чек-листа
- 🔲 Заполнить финальные параметры в `nsx-configs/segments.md`

---

## Вспомогательные файлы

- **[QUESTIONS-FOR-OPERATOR.md](./QUESTIONS-FOR-OPERATOR.md)**
  - Записывай сюда вопросы к AI-агенту

- **[screenshots/README.md](./screenshots/README.md)**
  - Директория для скриншотов NSX UI (опционально)

---

## Финальные артефакты (после завершения всех этапов)

**Будут заполнены в процессе:**

- **[../../nsx-configs/segments.md](../../nsx-configs/segments.md)**
  - Финальные параметры сегмента, IP-план, MTU, DNS
  - **Используется во всех последующих этапах K8s deployment!**

- **[../../nsx-configs/spoofguard-whitelist.md](../../nsx-configs/spoofguard-whitelist.md)**
  - Whitelist IP для kube-vip и MetalLB

- **../../nsx-configs/dfw-rules.json** (или скриншот)
  - Экспорт DFW правил из NSX UI

---

## Текущий прогресс

| Этап | Статус | Артефакты | Дата |
|------|--------|-----------|------|
| **Этап 1: Образовательная часть** | ✅ COMPLETED | 01, 02, 03 созданы | 2025-10-17 |
| **Этап 2: Исследование** | 🟡 TODO | 04 создан, 05 ожидает заполнения | - |
| **Этап 3: Анализ** | ⏸️ WAITING | 06 будет создан после Этапа 2 | - |
| **Этап 4: Настройка** | ⏸️ WAITING | 07 или 08 будут созданы | - |
| **Этап 5: Валидация** | ⏸️ WAITING | 09 создан (шаблон готов) | - |

---

## Следующий шаг (ДЛЯ ОПЕРАТОРА) 👇

1. ✅ **Прочитай образовательные материалы:**
   - [01-nsx-basics-for-k8s.md](./01-nsx-basics-for-k8s.md)
   - [02-tanzu-vs-standalone-k8s.md](./02-tanzu-vs-standalone-k8s.md)
   - [03-k8s-network-requirements.md](./03-k8s-network-requirements.md)

2. 🔲 **Открой NSX Manager UI** и заполни опросник:
   - [04-current-config-questionnaire.md](./04-current-config-questionnaire.md)
   - Скопируй в `05-investigation-results.md`

3. 🔲 **Сообщи AI-агенту:**
   - "Я заполнил 05-investigation-results.md, можешь проанализировать?"

4. ⏳ **AI-агент создаст:**
   - Рекомендацию в `06-decision-analysis.md`
   - Инструкции по настройке (07 или 08)

5. 🔲 **Ты применишь инструкции** в NSX UI

6. 🔲 **Валидация:** Пройдёшь чек-лист из `09-validation-checklist.md`

7. ✅ **Готово!** NSX-T настроен, переходим к VM Preparation (Этап 0.2)

---

## Контакты

**AI-агент:** Этот ассистент (отвечает на вопросы, создаёт документы)
**Оператор:** Ты (читаешь, заполняешь, применяешь)
**Координация:** Через PROJECT-PLAN.md (см. корень репозитория)

---

**Удачи! Начинай с чтения 01-nsx-basics-for-k8s.md! 🚀**
