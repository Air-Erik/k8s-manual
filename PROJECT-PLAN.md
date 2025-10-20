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

### 🟡 Этап 0: Подготовка инфраструктуры (IN PROGRESS)

**Ответственный:** Оператор-человек + AI-исполнитель
**Срок:** TBD
**Зависимости:** Нет

#### Задачи:

**0.1. NSX-T Network Investigation & Setup** 🟡 IN PROGRESS
- **Документ:** `docs/01-nsx-network-setup.md` → `research/nsx-analysis/AI-AGENT-TASK.md`
- **Исполнитель:** AI → создаёт образовательные материалы и инструкции, Оператор → исследует и применяет
- **Особенности:** NSX развернут не оператором, настроен под Tanzu. Требуется исследование перед изменениями.

**Этап 0.1.1 — Исследование (COMPLETED ✅):**
  - [x] AI-агент создаёт образовательные материалы:
  - [x] `research/nsx-analysis/01-nsx-basics-for-k8s.md`
  - [x] `research/nsx-analysis/02-tanzu-vs-standalone-k8s.md`
  - [x] `research/nsx-analysis/03-k8s-network-requirements.md`
  - [x] AI-агент создаёт опросник: `research/nsx-analysis/04-current-config-questionnaire.md`
  - [x] AI-агент создаёт вспомогательные файлы: README.md, QUESTIONS-FOR-OPERATOR.md, screenshots/README.md
  - [x] AI-агент создаёт шаблоны финальных документов: `nsx-configs/segments.md`, `nsx-configs/spoofguard-whitelist.md`
  - [x] Оператор изучил образовательные материалы
  - [x] Оператор исследовал NSX-T (сегмент VIP-VM, DFW, SpoofGuard, MTU)
  - [x] Оператор заполнил: `research/nsx-analysis/05-investigation-results.md`

**Этап 0.1.2 — Анализ и решение:**
  - [x] AI-агент анализирует собранные данные
  - [x] AI-агент создаёт рекомендацию: `research/nsx-analysis/06-decision-analysis.md`
  - [x] AI-агент ответил на вопросы оператора в `QUESTIONS-FOR-OPERATOR.md`
  - [ ] **← СЛЕДУЮЩИЙ ШАГ:** Оператор принимает решение: использовать VIP-VM или создать новый сегмент

**Этап 0.1.3 — Настройка:**
  - [x] AI-агент создаёт пошаговые инструкции: `research/nsx-analysis/08-setup-instructions-new-segment.md`
  - [ ] **← СЛЕДУЮЩИЙ ШАГ:** Оператор применяет инструкции в NSX UI
  - [ ] NSX-T Segment готов для k8s-нод (k8s-nodes-segment, 172.16.50.0/24)
  - [ ] IP-план зарезервирован (VM subnet, API VIP, MetalLB pool)
  - [ ] Группа `k8s-nodes` создана в NSX
  - [ ] DFW rules настроены (allow inter-node, NodePort, egress)
  - [ ] SpoofGuard whitelist настроен (VIP + MetalLB pool)
  - [ ] MTU проверен end-to-end

**Этап 0.1.4 — Валидация:**
  - [x] AI-агент создаёт чек-лист: `research/nsx-analysis/09-validation-checklist.md`
  - [ ] Оператор проверяет с тестовыми VM (connectivity, MTU, external access)
  - [ ] Финальные параметры задокументированы:
  - [ ] `nsx-configs/segments.md` (шаблон создан, ожидает заполнения)
  - [ ] `nsx-configs/spoofguard-whitelist.md` (шаблон создан, ожидает заполнения)
  - [ ] `nsx-configs/dfw-rules.json` (экспорт из NSX UI)

**0.2. VM Template Preparation**
- **Документ:** `docs/02-vm-preparation.md`
- **Исполнитель:** AI → создаёт инструкцию и скрипты, Оператор → создаёт VM
- **Артефакты:**
  - [ ] Ubuntu 24.04 VM создана в vSphere
  - [ ] Скрипт `scripts/prepare-vm.sh` создан
  - [ ] Cloud-init `vm-templates/cloud-init.yaml` создан
  - [ ] Список пакетов `vm-templates/packages-list.txt` создан
  - [ ] Kubernetes 1.34.x установлен
  - [ ] containerd настроен
  - [ ] sysctl настроен (ip_forward, bridge-nf-call)
  - [ ] swap отключен
  - [ ] VM Template создан в vSphere

**Критерии завершения этапа 0:**
- [ ] NSX-T сегмент готов, IP-план задокументирован
- [ ] VM Template готов, можно клонировать ноды
- [ ] Все настройки задокументированы и воспроизводимы

---

### 🔴 Этап 1: Bootstrap кластера (PoC) (TODO)

**Ответственный:** Оператор-человек + AI-исполнитель
**Срок:** TBD
**Зависимости:** Этап 0 завершён

#### Задачи:

**1.1. Cluster Bootstrap (kubeadm + kube-vip)**
- **Документ:** `docs/03-cluster-bootstrap.md`
- **Исполнитель:** AI → создаёт инструкцию и скрипты, Оператор → выполняет
- **Артефакты:**
  - [ ] 3 Control Plane VM созданы из шаблона
  - [ ] 2 Worker VM созданы из шаблона
  - [ ] kubeadm-config.yaml создан в `manifests/kube-vip/`
  - [ ] kube-vip Static Pod манифест создан
  - [ ] Скрипт `scripts/bootstrap-control-plane.sh` создан
  - [ ] Скрипт `scripts/join-worker.sh` создан
  - [ ] kubeadm init выполнен на первой CP ноде
  - [ ] kube-vip настроен на всех CP нодах
  - [ ] Остальные CP ноды joined
  - [ ] Worker ноды joined
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
- 🟡 Этап 0: Подготовка инфраструктуры — **IN PROGRESS** (60% — анализ завершён, инструкции готовы, ожидается настройка NSX)
- 🔴 Этап 1: Bootstrap кластера — **TODO** (0%)
- 🔴 Этап 2: Production-готовность — **TODO** (0%)
- 🔴 Этап 3: Миграция — **FUTURE** (0%)

### Следующие шаги (СЕЙЧАС):
1. ✅ **AI-агент** создал образовательные материалы по NSX-T (01-03) и опросник (04)
2. ✅ **AI-агент** создал все вспомогательные файлы и шаблоны
3. ✅ **Оператор** изучил материалы и исследовал NSX-T
4. ✅ **Оператор** заполнил 05-investigation-results.md и задал вопросы
5. ✅ **AI-агент** ответил на вопросы оператора
6. ✅ **AI-агент** проанализировал данные и создал рекомендацию (06-decision-analysis.md)
7. ✅ **AI-агент** создал пошаговые инструкции (08-setup-instructions-new-segment.md)
8. **Оператор** применяет инструкции в NSX-T ⬅️ **ВЫ ЗДЕСЬ**
   - Создать сегмент `k8s-nodes-segment` (172.16.50.0/24)
   - Настроить DFW правила
   - Провести валидацию с тестовыми VM
9. **Оператор** проходит валидацию (09-validation-checklist.md)
10. Переход к задаче 0.2 (VM Preparation)

---

## Риски и блокеры

| Риск | Вероятность | Влияние | Митигация | Статус |
|------|-------------|---------|-----------|--------|
| MTU несоответствие | Средняя | Высокое | Проверка MTU end-to-end, тесты | 🟡 Monitor |
| SpoofGuard блокирует VIP | Высокая | Критичное | Whitelist, тесты ARP | 🟡 Monitor |
| DFW блокирует трафик | Средняя | Высокое | Правильные DFW rules | 🟡 Monitor |
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
