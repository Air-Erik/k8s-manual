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

### 🔍 Этап 2: Исследование (COMPLETED ✅)

**Цель:** Собрать информацию о текущей NSX-T конфигурации.

4. **[04-current-config-questionnaire.md](./04-current-config-questionnaire.md)**
   - Опросник для заполнения (изучая NSX UI)
   - Вопросы о Tier-0/1, Segments, VIP-VM, DFW, SpoofGuard, MTU

**Действие оператора:**
- ✅ Открыть NSX Manager UI
- ✅ Заполнить все ответы в опроснике
- ✅ Скопировать файл: `cp 04-current-config-questionnaire.md 05-investigation-results.md`
- ✅ Сообщить AI-агенту: "Я заполнил 05-investigation-results.md"

---

### 🧠 Этап 3: Анализ (COMPLETED ✅)

**Цель:** На основе собранных данных дать рекомендацию.

6. **[06-decision-analysis.md](./06-decision-analysis.md)** ✅
   - Анализ: использовать VIP-VM или создать новый сегмент?
   - **Рекомендация:** Создать k8s-nodes-segment (172.16.50.0/24)
   - Обоснование, IP-план, риски, дорожная карта

**Действие оператора:**
- ✅ Прочитать рекомендацию AI-агента
- ✅ Принять решение: Создать новый сегмент k8s-nodes

---

### 🛠️ Этап 4: Настройка (IN PROGRESS 🟡)

**Цель:** Пошаговые инструкции для настройки NSX-T.

8. **[08-setup-instructions-new-segment.md](./08-setup-instructions-new-segment.md)** ✅
   - Пошаговые инструкции (6 частей, ~65 минут)
   - Создание Segment, Tier-1 Interface, DFW Group, DFW Rules
   - Валидация с тестовыми VM (7 тестов)
   - Troubleshooting для всех возможных проблем

**Действие оператора:**
- 🔲 **← СЕЙЧАС:** Применить инструкции в NSX UI
- 🔲 Создать segment k8s-nodes-segment (172.16.50.0/24)
- 🔲 Настроить DFW группу и правила
- 🔲 Провести валидацию с тестовыми VM

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
| **Этап 2: Исследование** | ✅ COMPLETED | 04, 05 заполнен | 2025-10-17 |
| **Этап 3: Анализ** | ✅ COMPLETED | 06 создан, вопросы отвечены | 2025-10-17 |
| **Этап 4: Настройка** | 🟡 IN PROGRESS | 08 создан, ожидается применение | 2025-10-17 |
| **Этап 5: Валидация** | ⏸️ TODO | 09 готов (применить после Этапа 4) | - |

---

## Следующий шаг (ДЛЯ ОПЕРАТОРА) 👇

1. ✅ Прочитай образовательные материалы (01-03)
2. ✅ Заполнил опросник (05-investigation-results.md)
3. ✅ Получил ответы на вопросы
4. ✅ Прочитал рекомендацию (06-decision-analysis.md)
5. ✅ Получил инструкции (08-setup-instructions-new-segment.md)

**← СЕЙЧАС ТЫ ЗДЕСЬ:**

6. 🔲 **Прочитай краткую сводку:**
   - 👉 **[NEXT-STEPS-SUMMARY.md](./NEXT-STEPS-SUMMARY.md)** ⭐ **НАЧНИ С ЭТОГО!**

7. 🔲 **Прочитай детальный анализ:**
   - [06-decision-analysis.md](./06-decision-analysis.md) (~10 минут)

8. 🔲 **Применишь инструкции в NSX UI:**
   - [08-setup-instructions-new-segment.md](./08-setup-instructions-new-segment.md) (~65 минут)
   - Создать сегмент k8s-nodes-segment (172.16.50.0/24)
   - Настроить DFW
   - Провести валидацию с тестовыми VM

9. 🔲 **Валидация:** Пройдёшь чек-лист из `09-validation-checklist.md`

10. ✅ **Готово!** NSX-T настроен, переходим к VM Preparation (Этап 0.2)

---

## Контакты

**AI-агент:** Этот ассистент (отвечает на вопросы, создаёт документы)
**Оператор:** Ты (читаешь, заполняешь, применяешь)
**Координация:** Через PROJECT-PLAN.md (см. корень репозитория)

---

**Удачи! Начинай с чтения 01-nsx-basics-for-k8s.md! 🚀**
