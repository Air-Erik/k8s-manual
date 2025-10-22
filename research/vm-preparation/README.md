# VM Template Preparation Research

Эта папка содержит исследования, инструкции и скрипты для подготовки VM Template для Kubernetes нод.

## Статус

**Текущий этап:** 🟡 Подготовка к передаче AI-агенту
**Зависимости:** ✅ NSX-T настроен (Этап 0.1 завершён)

## Главный документ

**[AI-AGENT-TASK.md](./AI-AGENT-TASK.md)** — детальное задание для AI-агента

Содержит:
- 5 этапов работы (анализ → инструкции → скрипты → cloud-init → валидация)
- 8 документов для создания
- 3+ скрипта автоматизации
- Cloud-init конфигурации
- Валидационные процедуры

## Цель

Создать готовый к использованию VM Template Ubuntu 24.04 LTS с предустановленными:
- Kubernetes компонентами (kubeadm, kubelet, kubectl)
- containerd (CRI)
- Правильными системными настройками (sysctl, swap off)
- Cloud-init для автоматизации клонирования

## Исходные данные (из NSX-T конфигурации)

- **Segment:** `k8s-zeon-dev-segment`
- **Subnet:** `10.246.10.0/24`
- **Gateway:** `10.246.10.1`
- **Control Plane IPs:** `10.246.10.10-12`
- **Worker IPs:** `10.246.10.20-30`
- **API VIP:** `10.246.10.100`

## Ожидаемые артефакты

### Документация (`research/vm-preparation/`)
- `01-version-analysis.md` — анализ совместимости версий K8s/containerd/Ubuntu
- `02-template-strategy.md` — стратегия создания Template (единый vs раздельные)
- `03-base-vm-creation.md` — пошаговое создание базовой VM в vSphere
- `04-k8s-installation.md` — установка и настройка K8s компонентов
- `05-template-finalization.md` — подготовка VM к созданию Template
- `06-validation-checklist.md` — проверочные процедуры
- `07-first-clone-test.md` — тестирование клонирования из Template
- `08-final-documentation.md` — итоговая сводка

### Скрипты (`scripts/`)
- `prepare-vm.sh` — основной скрипт подготовки VM
- `validate-vm-template.sh` — валидация готовности Template
- `cleanup-vm-for-template.sh` — очистка перед созданием Template

### Cloud-init конфигурации (`vm-templates/`)
- `cloud-init-base.yaml` — базовая конфигурация
- `cloud-init-control-plane.yaml` — для Control Plane нод
- `cloud-init-worker.yaml` — для Worker нод
- `examples/README.md` — примеры использования
- `packages-list.txt` — список установленных пакетов

## Процесс работы

1. **Оператор** передаёт задачу AI-агенту (см. главную инструкцию в корне)
2. **AI-агент** создаёт все документы и скрипты согласно заданию
3. **Оператор** выполняет инструкции на реальной vSphere инфраструктуре
4. **Валидация** — первый тестовый клон из Template
5. **Готовность** к следующему этапу (Cluster Bootstrap)

## Критерии успеха

- ✅ VM Template создан в vSphere
- ✅ Все K8s компоненты предустановлены
- ✅ Cloud-init готов к автоматизации
- ✅ Тестовое клонирование прошло успешно
- ✅ Готовность к kubeadm init/join

## Следующий этап

После завершения этой задачи: **Этап 1.1 — Cluster Bootstrap** (kubeadm + kube-vip)

---

**Начинай с AI-AGENT-TASK.md!**
