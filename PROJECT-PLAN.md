# Project Master Plan: Kubernetes на vSphere с NSX-T

> **Team Lead:** AI Orchestrator
> **Версия:** 1.0
> **Дата создания:** 2025-10-17
> **Статус проекта:** 🟡 Подготовка к реализации

---

## Обзор проекта

Развёртывание production-ready Kubernetes кластера на VMware vSphere с NSX-T underlay сетью.

**Ключевые документы:**
- [k8s-on-vsphere-nsx-context.md](./k8s-on-vsphere-nsx-context.md) — техническое задание
- [README.md](./README.md) — обзор репозитория

---

## Этапы проекта

### ✅ Этап -1: Инициализация репозитория (COMPLETED)

**Цель:** Создать структуру репозитория и документацию

**Задачи:**
- [x] Создать и дополнить контекстный документ
- [x] Создать структуру директорий
- [x] Создать README.md
- [x] Создать заглушки для документов в docs/
- [x] Создать .gitignore
- [x] Создать PROJECT-PLAN.md

**Результат:** Репозиторий готов к работе AI-исполнителей.

---

### ✅ Этап 0: Подготовка инфраструктуры (COMPLETED)

**Ответственный:** Оператор-человек + AI-исполнитель
**Срок:** TBD
**Зависимости:** Нет

#### Задачи:

**0.1. NSX-T Network Investigation & Setup** ✅ COMPLETED
- **Документ:** `docs/01-nsx-network-setup.md` → `research/nsx-analysis/AI-AGENT-TASK.md`
- **Исполнитель:** AI → создаёт образовательные материалы и инструкции, Оператор → исследует и применяет
- **Особенности:** NSX развернут не оператором, настроен под Tanzu. Требуется исследование перед изменениями.
- **Результат:** Создан отдельный T1 Gateway + изолированный сегмент для k8s кластера
- **Ключевые параметры:**
  - **T1 Gateway:** `T1-k8s-zeon-dev` (отдельный T1 для k8s)
  - **Сегмент:** `k8s-zeon-dev-segment` (10.246.10.0/24)
  - **Gateway IP:** `10.246.10.1/24`
  - **SNAT IP:** `172.16.50.170` (egress в интернет)
  - **VIP Pool:** `172.16.50.192/27` (для LoadBalancer/Ingress)
  - **NAT правила:** 3 правила для корректной маршрутизации

**Этап 0.1.1 — Исследование (COMPLETED ✅):**
  - [x] AI-агент создаёт образовательные материалы:
  - [x] `research/nsx-analysis/01-nsx-basics-for-k8s.md`
  - [x] `research/nsx-analysis/02-tanzu-vs-standalone-k8s.md`
  - [x] `research/nsx-analysis/03-k8s-network-requirements.md`
  - [x] AI-агент создаёт опросник: `research/nsx-analysis/04-current-config-questionnaire.md`
  - [x] AI-агент создаёт вспомогательные файлы: README.md, QUESTIONS-FOR-OPERATOR.md, screenshots/README.md
  - [x] AI-агент создаёт шаблоны финальных документов: `nsx-configs/segments.md`, `nsx-configs/spoofguard-whitelist.md`
  - [x] **Созданы финальные документы конфигурации:**
    - [x] `nsx-configs/segments.md` ✅ (заполнен полностью)
    - [x] `nsx-configs/t1-gateway-config.md` ✅ (создан новый)
    - [x] `nsx-configs/nat-configuration.md` ✅ (создан новый)
    - [x] `nsx-configs/README.md` ✅ (создан обзорный документ)
  - [x] Оператор изучил образовательные материалы
  - [x] Оператор исследовал NSX-T (сегмент VIP-VM, DFW, SpoofGuard, MTU)
  - [x] Оператор заполнил: `research/nsx-analysis/05-investigation-results.md`

**Этап 0.1.2 — Анализ и решение (COMPLETED ✅):**
  - [x] AI-агент анализирует собранные данные
  - [x] AI-агент создаёт рекомендацию: `research/nsx-analysis/06-decision-analysis.md`
  - [x] AI-агент ответил на вопросы оператора в `QUESTIONS-FOR-OPERATOR.md`
  - [x] **Оператор принял решение:** создать отдельный T1 Gateway + новый сегмент

**Этап 0.1.3 — Настройка (COMPLETED ✅):**
  - [x] AI-агент создаёт пошаговые инструкции: `research/nsx-analysis/08-setup-instructions-new-segment.md`
  - [x] **Оператор применил инструкции в NSX UI:**
  - [x] **Создан T1 Gateway:** `T1-k8s-zeon-dev` (отдельный T1 для k8s кластера)
  - [x] **Создан сегмент:** `k8s-zeon-dev-segment` (10.246.10.0/24)
  - [x] **Настроены NAT правила:** 3 правила для корректной маршрутизации
  - [x] **Route Advertisement включён:** Connected Segments + NAT IPs
  - [x] **Сетевая изоляция обеспечена:** отдельный T1 + собственная подсеть

**Этап 0.1.4 — Валидация (COMPLETED ✅):**
  - [x] AI-агент создаёт чек-лист: `research/nsx-analysis/09-validation-checklist.md`
  - [x] **Оператор проверил с тестовыми VM:** connectivity, external access работает через SNAT
  - [x] **Финальные параметры задокументированы:**
  - [x] `nsx-configs/segments.md` ✅ (заполнен полностью)
  - [x] `nsx-configs/t1-gateway-config.md` ✅ (создан новый)
  - [x] `nsx-configs/nat-configuration.md` ✅ (создан новый)
  - [x] `nsx-configs/README.md` ✅ (создан обзорный документ)

**0.2. VM Template Preparation** ✅ COMPLETED
- **Документ:** `docs/02-vm-preparation.md` → `research/vm-preparation/AI-AGENT-TASK.md`
- **Исполнитель:** AI → создаёт инструкцию и скрипты, Оператор → создаёт VM
- **Результат:** Создан готовый к использованию VM Template с cloud-init автоматизацией
- **Артефакты:**
  - [x] **Ubuntu 24.04 VM создана** в vSphere ✅
  - [x] **Скрипты созданы:** `scripts/prepare-vm.sh`, `validate-vm-template.sh`, `cleanup-vm-for-template.sh` ✅
  - [x] **Cloud-init конфигурации:** `vm-templates/cloud-init-*.yaml` (base, control-plane, worker) ✅
  - [x] **Документация:** полные инструкции и анализ версий в `research/vm-preparation/` ✅
  - [x] **Kubernetes установлен** (актуальная стабильная версия вместо 1.34.x) ✅
  - [x] **containerd настроен** ✅
  - [x] **sysctl настроен** (ip_forward, bridge-nf-call) ✅
  - [x] **swap отключен** ✅
  - [x] **VM Template создан** в vSphere ✅
  - [x] **Первое клонирование протестировано** с cloud-init ✅

**Критерии завершения этапа 0:**
- [x] **NSX-T сегмент готов, IP-план задокументирован** ✅ (T1-k8s-zeon-dev + k8s-zeon-dev-segment)
- [x] **VM Template готов, можно клонировать ноды** ✅ (Template создан и протестирован)
- [x] **Все настройки задокументированы и воспроизводимы** ✅ (research/vm-preparation/ + nsx-configs/)

---

### 🟡 Этап 1: Bootstrap кластера (PoC) (NEXT)

**Ответственный:** Оператор-человек + AI-исполнитель
**Срок:** TBD
**Зависимости:** ✅ Этап 0 завершён

#### Задачи:

**1.1. Cluster Bootstrap (kubeadm + kube-vip)** 🟡 READY
- **Документ:** `docs/03-cluster-bootstrap.md` → `research/cluster-bootstrap/AI-AGENT-TASK.md`
- **Исполнитель:** AI → создаёт kubeadm конфиги и скрипты, Оператор → разворачивает
- **Цель:** Инициализировать HA Kubernetes кластер с kube-vip для API VIP
- **Артефакты:**
  - [ ] 5 VM клонированы из Template (3 CP + 2 Workers)
  - [ ] kube-vip настроен для API VIP (10.246.10.100)
  - [ ] kubeadm конфигурации созданы (CP, join-CP, join-Worker)
  - [ ] Первый CP инициализирован (kubeadm init)
  - [ ] Остальные CP присоединены (HA etcd stacked topology)
  - [ ] Worker ноды присоединены
  - [ ] Кластер валидирован (API доступен через VIP, все поды работают)
  - [ ] API VIP доступен
  - [ ] kubeconfig получен оператором

**1.2. CNI Setup (Cilium)**
- **Документ:** `docs/04-cni-setup.md`
- **Исполнитель:** AI → создаёт инструкцию и values.yaml, Оператор → применяет
- **Артефакты:**
  - [ ] MTU определён и задокументирован
  - [ ] Cilium values.yaml создан в `manifests/cilium/`
  - [ ] Cilium установлен в кластер
  - [ ] Все ноды в статусе **Ready**
  - [ ] `cilium status` показывает OK
  - [ ] `cilium connectivity test` пройден
  - [ ] (Опционально) Hubble UI развёрнут

**1.3. Storage Setup (vSphere CSI)**
- **Документ:** `docs/05-storage-setup.md`
- **Исполнитель:** AI → создаёт инструкцию и манифесты, Оператор → применяет
- **Артефакты:**
  - [ ] Датастор определён
  - [ ] vSphere CSI Secret создан (с vCenter credentials)
  - [ ] vSphere CSI Driver установлен
  - [ ] StorageClass создан и помечен как default
  - [ ] Тестовый PVC создан и успешно provisioned
  - [ ] Тестовый pod монтирует PVC и может писать/читать
  - [ ] Манифесты в `manifests/vsphere-csi/`

**1.4. MetalLB Setup**
- **Документ:** `docs/06-metallb-setup.md`
- **Исполнитель:** AI → создаёт инструкцию и манифесты, Оператор → применяет
- **Артефакты:**
  - [ ] IP-диапазон MetalLB зарезервирован и задокументирован
  - [ ] MetalLB установлен
  - [ ] IPAddressPool создан
  - [ ] L2Advertisement создан
  - [ ] Тестовый Service LoadBalancer получает External IP
  - [ ] Доступ к сервису по External IP работает
  - [ ] Манифесты в `manifests/metallb/`

**1.5. Ingress Setup (NGINX)**
- **Документ:** `docs/07-ingress-setup.md`
- **Исполнитель:** AI → создаёт инструкцию и values/манифесты, Оператор → применяет
- **Артефакты:**
  - [ ] NGINX Ingress Controller установлен
  - [ ] Ingress Service получил LoadBalancer IP
  - [ ] Тестовый Deployment + Service + Ingress созданы
  - [ ] HTTP доступ через Ingress работает
  - [ ] (Опционально) HTTPS с self-signed cert настроен
  - [ ] Манифесты в `manifests/ingress-nginx/`

**Критерии завершения этапа 1:**
- [ ] Кластер полностью функционален (API, ноды Ready)
- [ ] Pod networking работает (Cilium connectivity test OK)
- [ ] Storage provisioning работает (PVC создаётся)
- [ ] Service LoadBalancer работает (MetalLB выдаёт IP)
- [ ] Ingress маршрутизирует трафик (HTTP доступ есть)

---

### 🔴 Этап 2: Production-готовность (TODO)

**Ответственный:** Оператор-человек + AI-исполнитель
**Срок:** TBD
**Зависимости:** Этап 1 завершён

#### Задачи:

**2.1. Observability Setup**
- **Документ:** `docs/08-observability-setup.md`
- **Исполнитель:** AI → создаёт инструкцию, Оператор → применяет
- **Артефакты:**
  - [ ] metrics-server установлен
  - [ ] `kubectl top nodes/pods` работает
  - [ ] (Опционально для Prod) Prometheus установлен
  - [ ] (Опционально) Grafana установлена с дашбордами
  - [ ] (Опционально) Hubble UI доступен
  - [ ] Манифесты в `manifests/observability/`

**2.2. Backup Setup**
- **Документ:** `docs/09-backup-setup.md`
- **Исполнитель:** AI → создаёт инструкцию и скрипты, Оператор → применяет
- **Артефакты:**
  - [ ] Velero установлен
  - [ ] Backend для Velero настроен (S3/vSphere)
  - [ ] Тестовый backup/restore проверен
  - [ ] Скрипт `scripts/etcd-backup.sh` создан и проверен
  - [ ] (Опционально) CronJob для автоматических backup
  - [ ] Runbook по восстановлению создан
  - [ ] Манифесты в `manifests/backup/`

**2.3. Security Hardening**
- **Документ:** Создать `docs/11-security-hardening.md`
- **Исполнитель:** AI → создаёт инструкцию, Оператор → применяет
- **Артефакты:**
  - [ ] Pod Security Admission (PSA) настроен
  - [ ] Базовые NetworkPolicy созданы
  - [ ] RBAC проверен и минимизирован
  - [ ] (Опционально) Image scanning (Trivy)
  - [ ] Манифесты в `manifests/security/`

**2.4. Testing & Validation**
- **Документ:** `docs/10-testing-validation.md`
- **Исполнитель:** AI → создаёт тесты и чек-листы, Оператор → выполняет
- **Артефакты:**
  - [ ] Все чек-листы из раздела 13 контекста выполнены
  - [ ] Stress-тесты проведены (опционально)
  - [ ] Документация проверена на актуальность
  - [ ] Тестовые манифесты в `manifests/examples/`

**Критерии завершения этапа 2:**
- [ ] Мониторинг работает, метрики видны
- [ ] Backup/restore проверены и документированы
- [ ] Security baseline применён
- [ ] Все критерии успеха из раздела 9 контекста выполнены
- [ ] Кластер готов к переносу реальных workloads

---

### 🔴 Этап 3: Миграция и масштабирование (FUTURE)

**Ответственный:** TBD
**Срок:** TBD
**Зависимости:** Этап 2 завершён, решение принято руководством

#### Задачи:
- Планирование миграции workloads от Tanzu
- Создание Prod-кластера (увеличенные ресурсы)
- Настройка CI/CD (Argo CD/Flux)
- Настройка ExternalDNS
- Интеграция с корпоративным мониторингом/логами
- Процедуры отката

**Документация:** Будет создана позже.

---

## Tracking прогресса

### Общий статус этапов:
- ✅ Этап -1: Инициализация — **COMPLETED** (100%)
- ✅ Этап 0: Подготовка инфраструктуры — **COMPLETED** (100% — NSX-T + VM Template готовы)
- 🟡 Этап 1: Bootstrap кластера — **NEXT** (0% — готов к началу)
- 🔴 Этап 2: Production-готовность — **TODO** (0%)
- 🔴 Этап 3: Миграция — **FUTURE** (0%)

### Прогресс Этапа 0 (завершён ✅):
1. ✅ **NSX-T Investigation & Setup завершён**
   - ✅ Создан T1 Gateway `T1-k8s-zeon-dev`
   - ✅ Создан сегмент `k8s-zeon-dev-segment` (10.246.10.0/24)
   - ✅ Настроены NAT правила, проведена валидация
   - ✅ Параметры задокументированы в `nsx-configs/`

2. ✅ **VM Template Preparation завершён**
   - ✅ VM Template создан в vSphere с предустановленными K8s компонентами
   - ✅ Скрипты автоматизации созданы (`scripts/prepare-vm.sh`, validate, cleanup)
   - ✅ Cloud-init конфигурации готовы (`vm-templates/cloud-init-*.yaml`)
   - ✅ Первое клонирование протестировано
   - ✅ Полная документация в `research/vm-preparation/`

### Следующие шаги (СЕЙЧАС):
**← СЛЕДУЮЩИЙ ШАГ:** Переход к **Этапу 1.1 (Cluster Bootstrap)** ⬅️ **ВЫ ЗДЕСЬ**

---

## Риски и блокеры

| Риск | Вероятность | Влияние | Митигация | Статус |
|------|-------------|---------|-----------|--------|
| MTU несоответствие | Средняя | Высокое | Проверка MTU end-to-end, тесты | 🟢 **RESOLVED** (NSX настроен) |
| SpoofGuard блокирует VIP | Высокая | Критичное | Whitelist, тесты ARP | 🟢 **RESOLVED** (отдельный T1) |
| DFW блокирует трафик | Средняя | Высокое | Правильные DFW rules | 🟢 **RESOLVED** (NAT правила) |
| Версии несовместимы (k8s 1.34) | Низкая | Среднее | Проверка совместимости | 🟢 OK |
| Датастор нестабилен | Низкая | Высокое | Выбор надёжного датастора | 🟢 OK |

---

## Контакты и роли

| Роль | Ответственный | Функции |
|------|---------------|---------|
| **AI Team Lead** | Этот ассистент | Координация, планирование, валидация |
| **AI-исполнители** | Другие ассистенты | Создание артефактов по инструкциям |
| **Оператор-человек** | Вы | Физическое выполнение, feedback |
| **Валидатор** | Оператор + Team Lead | Проверка критериев успеха |

---

**Обновления плана:** Этот документ обновляется по мере прогресса проекта.
