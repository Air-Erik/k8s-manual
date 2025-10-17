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

### Этап 0.1: NSX-T Investigation 🟡 IN PROGRESS (25%)

#### Status
- ✅ **Этап 1 (Образовательная часть) ЗАВЕРШЁН**
- 🟡 Ожидается изучение материалов оператором и исследование NSX-T

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

#### Next Steps
1. ✅ AI-агент создал все образовательные материалы
2. **Оператор изучает материалы** (research/nsx-analysis/01-03) ⬅️ **СЕЙЧАС**
3. Оператор исследует NSX-T и заполняет 05-investigation-results.md
4. AI-агент анализирует данные → создаёт 06-decision-analysis.md
5. AI-агент создаёт инструкции по настройке (07 или 08)
6. Оператор применяет инструкции в NSX UI
7. Оператор проходит валидацию (09-validation-checklist.md)
8. Финальные параметры фиксируются в nsx-configs/

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
