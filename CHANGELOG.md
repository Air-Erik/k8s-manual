# Changelog

## [Unreleased] - 2025-10-17

### Этап -1: Инициализация репозитория ✅ COMPLETED

#### Added
- **Контекстный документ** `k8s-on-vsphere-nsx-context.md` с полным ТЗ:
  - Раздел 15: Конкретные параметры инфраструктуры (версии, размеры VM, IP-адресация)
  - Раздел 16: Решения для PoC (Cilium, MetalLB L2, NGINX, vSphere CSI)
  - Раздел 17: Структура репозитория
  - Раздел 18: Роли и процесс работы
  - Расширенный раздел 10: Риски с конкретными чек-листами и командами
  - Обновлённый раздел 11: Открытые вопросы (решённые и TBD)

- **Структура директорий:**
  ```
  docs/              - Пошаговые мануалы
  manifests/         - Kubernetes манифесты
  scripts/           - Bash-скрипты автоматизации
  nsx-configs/       - Описания NSX-T конфигураций
  vm-templates/      - Cloud-init и спецификации VM
  research/          - Исследования и теория
  ```

- **Документация:**
  - `README.md` - Обзор проекта и быстрый старт
  - `PROJECT-PLAN.md` - Мастер-план с этапами и задачами
  - `HOW-TO-DELEGATE-TO-AI.md` - Инструкция по передаче задач AI-агентам
  - `docs/01-nsx-network-setup.md` - Обновлён с ссылкой на research
  - `docs/02-vm-preparation.md` - Заглушка для VM preparation
  - `docs/03-cluster-bootstrap.md` - Заглушка для cluster bootstrap
  - `docs/04-cni-setup.md` - Заглушка для Cilium setup
  - `docs/05-storage-setup.md` - Заглушка для vSphere CSI
  - `docs/06-metallb-setup.md` - Заглушка для MetalLB
  - `docs/07-ingress-setup.md` - Заглушка для NGINX Ingress
  - `docs/08-observability-setup.md` - Заглушка для observability
  - `docs/09-backup-setup.md` - Заглушка для Velero/etcd backup
  - `docs/10-testing-validation.md` - Заглушка для тестирования
  - `docs/99-troubleshooting.md` - Руководство по решению проблем

- **Research материалы:**
  - `research/README.md` - Обзор исследовательских материалов
  - `research/nsx-analysis/AI-AGENT-TASK.md` - **Детальная задача для AI-агента по NSX**
    - Этап 1: Образовательная часть (NSX basics, Tanzu vs Standalone)
    - Этап 2: Исследование текущей конфигурации (опросник)
    - Этап 3: Анализ и принятие решений (VIP-VM vs новый сегмент)
    - Этап 4: Создание пошаговых инструкций
    - Этап 5: Валидация и документация

- **Вспомогательные файлы:**
  - `.gitignore` - Исключения для Git (секреты, сертификаты, backups)
  - `CHANGELOG.md` - Этот файл

#### Changed
- `docs/01-nsx-network-setup.md` - Обновлён с фокусом на исследование перед настройкой
- `PROJECT-PLAN.md` - Обновлён статус Этапа 0 (IN PROGRESS, 5%)

#### Fixed
- N/A (первая версия)

---

### Этап 0.1: NSX-T Investigation ✅ COMPLETED (100%)

#### Status
- ✅ **Все этапы завершены**
- ✅ NSX-T сеть настроена и задокументирована

### Этап 0.2: VM Template Preparation ✅ COMPLETED (100%)

#### Status
- ✅ **VM Template создан и протестирован**
- ✅ Скрипты автоматизации готовы
- ✅ Cloud-init конфигурации созданы

#### Added (2025-10-17)

**Образовательные материалы:**
- `research/nsx-analysis/01-nsx-basics-for-k8s.md` — Основы NSX-T для Kubernetes
  - Tier-0/1 Gateway, Segments, DFW, SpoofGuard, MTU
  - Архитектурные диаграммы (ASCII art)
  - Практические примеры для K8s use-case
- `research/nsx-analysis/02-tanzu-vs-standalone-k8s.md` — Tanzu vs Standalone
  - NSX as CNI (NCP) vs NSX as underlay (наш случай)
  - Сравнительная таблица, схемы сосуществования
  - Почему не используем NCP
- `research/nsx-analysis/03-k8s-network-requirements.md` — Сетевые требования
  - Полный чек-лист: Segment, IP-план, DFW, SpoofGuard, MTU, DNS
  - Таблицы портов, примеры IP-планов
  - Команды для проверки

**Опросники и инструкции:**
- `research/nsx-analysis/04-current-config-questionnaire.md` — Опросник для исследования NSX
  - 10 разделов: Tier-0/1, Segments, VIP-VM, DFW, SpoofGuard, MTU, NAT, DNS, Tanzu
  - Детальные вопросы с указанием путей в NSX UI
- `research/nsx-analysis/09-validation-checklist.md` — Чек-лист валидации после настройки
  - 8 разделов проверок (connectivity, DFW, SpoofGuard, MTU, DNS)
  - Команды для тестирования, troubleshooting секция

**Финальные шаблоны:**
- `nsx-configs/segments.md` — Шаблон для финальной конфигурации сегмента
  - Segment info, IP allocation plan, MTU, DNS, NAT, DFW, SpoofGuard
  - Таблицы для заполнения, чек-листы валидации
- `nsx-configs/spoofguard-whitelist.md` — Документация SpoofGuard whitelist
  - Инструкции для API VIP и MetalLB pool
  - Шаги настройки в NSX UI, troubleshooting
  - Security considerations (PoC vs Prod)

**Вспомогательные файлы:**
- `research/nsx-analysis/README.md` — Обзор всех документов, roadmap
- `research/nsx-analysis/START-HERE.md` — Быстрый старт для оператора
- `research/nsx-analysis/QUESTIONS-FOR-OPERATOR.md` — Шаблон для вопросов
- `research/nsx-analysis/screenshots/README.md` — Инструкции для скриншотов NSX UI

#### Added (Этап 0.1.2 — Анализ и решение, 2025-10-17)

**Анализ данных:**
- `research/nsx-analysis/06-decision-analysis.md` — Детальный анализ NSX-T конфигурации
  - Анализ текущей ситуации (VIP-VM, DFW, SpoofGuard, MTU, connectivity)
  - Сравнение вариантов (использовать VIP-VM vs создать новый сегмент)
  - Рекомендация: **Создать k8s-nodes-segment (172.16.50.0/24)**
  - IP Allocation Plan (87 IP используется, 167 свободно)
  - Дорожная карта реализации (~65 минут)
  - Анализ рисков и митигация

**Инструкции по настройке:**
- `research/nsx-analysis/08-setup-instructions-new-segment.md` — Пошаговые инструкции
  - ЧАСТЬ 1: Создание Segment (15 минут)
  - ЧАСТЬ 2: Проверка Tier-1 Gateway Interface (5 минут)
  - ЧАСТЬ 3: Создание DFW Group (5 минут)
  - ЧАСТЬ 4: Создание DFW Rules (10 минут)
  - ЧАСТЬ 5: Валидация с тестовыми VM (30 минут, 7 тестов)
  - ЧАСТЬ 6: Финальная документация (10 минут)
  - Troubleshooting секция для всех возможных проблем

**Ответы на вопросы:**
- `research/nsx-analysis/QUESTIONS-FOR-OPERATOR.md` (обновлён) — Ответы AI-агента
  - SpoofGuard: скорее всего выключен (проверим при тестировании)
  - DHCP: не критичен, будем использовать статические IP
  - Отдельный сегмент: правильное решение ✅
  - IP-адреса: можно использовать любые приватные (рекомендовано 172.16.50.0/24)

**Вспомогательные файлы:**
- `research/nsx-analysis/NEXT-STEPS-SUMMARY.md` — Краткая сводка для оператора
  - Что выяснили, рекомендация, IP-план
  - Ответы на вопросы, что делать дальше
  - Оценка времени (~1.5 часа)

#### Completed (NSX-T + VM Template)
1. ✅ AI-агент создал все образовательные материалы
2. ✅ Оператор изучил материалы и исследовал NSX-T
3. ✅ Оператор заполнил 05-investigation-results.md и задал вопросы
4. ✅ AI-агент ответил на вопросы
5. ✅ AI-агент проанализировал данные → создал 06-decision-analysis.md
6. ✅ AI-агент создал инструкции: 08-setup-instructions-new-segment.md
7. ✅ **Оператор применил инструкции в NSX UI**
   - ✅ Создан T1 Gateway T1-k8s-zeon-dev
   - ✅ Создан сегмент k8s-zeon-dev-segment (10.246.10.0/24)
   - ✅ Настроены NAT правила
   - ✅ Проведена валидация с тестовыми VM
8. ✅ Оператор прошёл валидацию (09-validation-checklist.md)
9. ✅ Финальные параметры зафиксированы в nsx-configs/
10. ✅ **VM Template Preparation завершён**
   - ✅ VM Template создан в vSphere
   - ✅ Скрипты автоматизации созданы
   - ✅ Cloud-init конфигурации готовы
   - ✅ Первое клонирование протестировано

#### Next Steps
**← СЛЕДУЮЩИЙ ЭТАП:** Cluster Bootstrap (kubeadm + kube-vip) ⬅️ **Team Lead готовит задание**

---

## Планы на следующие версии

### Этап 0: Подготовка инфраструктуры (TODO)
- [ ] Детализация NSX-T network setup инструкций
- [ ] Создание скриптов подготовки VM
- [ ] Cloud-init конфигурации
- [ ] Определение финальных IP-параметров

### Этап 1: Bootstrap кластера (TODO)
- [ ] kubeadm + kube-vip манифесты и скрипты
- [ ] Cilium values.yaml
- [ ] vSphere CSI манифесты
- [ ] MetalLB манифесты
- [ ] NGINX Ingress манифесты
- [ ] Тестовые примеры приложений

### Этап 2: Production-готовность (TODO)
- [ ] Prometheus/Grafana setup (опционально)
- [ ] Velero конфигурация
- [ ] Security policies (PSA, NetworkPolicy)
- [ ] Comprehensive testing suite

---

**Версия репозитория:** 0.1.0-alpha
**Последнее обновление:** 2025-10-17
