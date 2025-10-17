# Kubernetes на vSphere с NSX-T (без Tanzu)

Репозиторий содержит полный набор инструкций, манифестов и скриптов для развёртывания **production-ready Kubernetes кластера** на виртуальных машинах VMware vSphere с сетевым underlay на NSX-T.

## 🎯 Цель проекта

Развернуть самостоятельный Kubernetes-кластер (kubeadm) на VM под vSphere, использующий NSX-T как underlay-сеть (без NCP), с полным набором компонентов:
- HA Control Plane (kube-vip)
- CNI: Cilium
- LoadBalancer: MetalLB (L2)
- Ingress: NGINX
- Storage: vSphere CSI
- Observability: metrics-server, Prometheus/Grafana (опционально)
- Backup: Velero + etcd snapshots

## 📋 Документация

**Начните с контекстного документа:**
- **[k8s-on-vsphere-nsx-context.md](./k8s-on-vsphere-nsx-context.md)** — техническое задание, архитектура, решения, риски

**Пошаговые мануалы:**
1. `docs/01-nsx-network-setup.md` — Настройка NSX-T (Segment, IP-план, DFW, SpoofGuard)
2. `docs/02-vm-preparation.md` — Подготовка VM-шаблонов (Ubuntu 24.04, containerd, sysctl)
3. `docs/03-cluster-bootstrap.md` — kubeadm init, kube-vip, join workers
4. `docs/04-cni-setup.md` — Установка Cilium
5. `docs/05-storage-setup.md` — vSphere CSI Driver
6. `docs/06-metallb-setup.md` — MetalLB LoadBalancer
7. `docs/07-ingress-setup.md` — NGINX Ingress Controller
8. `docs/08-observability-setup.md` — Мониторинг и логи
9. `docs/09-backup-setup.md` — Velero и etcd backups
10. `docs/10-testing-validation.md` — Тестовые workloads и валидация
11. `docs/99-troubleshooting.md` — Решение проблем

## 🗂️ Структура репозитория

```
k8s-manual/
├── README.md                          # Этот файл
├── k8s-on-vsphere-nsx-context.md      # Источник правды (контекст задачи)
├── PROJECT-PLAN.md                    # Мастер-план проекта с этапами
├── HOW-TO-DELEGATE-TO-AI.md          # Инструкция по работе с AI-агентами
│
├── docs/                              # Пошаговые мануалы
├── research/                          # Исследования и образовательные материалы
│   └── nsx-analysis/                  # NSX-T investigation (ACTIVE)
├── manifests/                         # Kubernetes манифесты (организованы по компонентам)
├── scripts/                           # Bash-скрипты для автоматизации
├── nsx-configs/                       # Описания NSX-T конфигураций
└── vm-templates/                      # Cloud-init и спецификации VM
```

## 🔧 Технологический стек

| Компонент | Решение | Версия |
|-----------|---------|--------|
| **Kubernetes** | kubeadm | 1.34.x |
| **ОС нод** | Ubuntu | 24.04 LTS |
| **Container Runtime** | containerd | latest stable |
| **CNI** | Cilium | latest stable |
| **LoadBalancer** | MetalLB | L2 mode |
| **Ingress** | NGINX Ingress | latest stable |
| **CSI** | vSphere CSI Driver | compatible with vSphere 8.0 |
| **API HA** | kube-vip | latest stable |
| **Observability** | metrics-server | latest stable |
| **Backup** | Velero + etcdctl | latest stable |

**Инфраструктура:**
- vSphere 8.0.3.00500
- NSX-T 4.2.3.0.0

## 🚀 Быстрый старт

### 📍 Текущий этап: NSX-T Investigation (Этап 0.1)

**Статус:** 🟡 Готово к передаче AI-агенту

**Что делать сейчас:**
1. **Прочитайте** [k8s-on-vsphere-nsx-context.md](./k8s-on-vsphere-nsx-context.md) для понимания контекста
2. **Прочитайте** [HOW-TO-DELEGATE-TO-AI.md](./HOW-TO-DELEGATE-TO-AI.md) — инструкция по работе с AI-агентами
3. **Передайте задачу AI-агенту:**
   - Откройте файл [research/nsx-analysis/AI-AGENT-TASK.md](./research/nsx-analysis/AI-AGENT-TASK.md)
   - Следуйте инструкциям из HOW-TO-DELEGATE-TO-AI.md
   - AI-агент создаст образовательные материалы и поможет исследовать NSX
4. **После NSX setup:** переходите к VM preparation

---

### Этап 0: Подготовка (для справки)
1. ~~Прочитайте контекстный документ~~ ✅
2. **→ Настройте NSX-T сеть: `docs/01-nsx-network-setup.md`** ⬅️ ВЫ ЗДЕСЬ
3. Подготовьте VM-шаблоны: `docs/02-vm-preparation.md`

### Этап 1: Bootstrap кластера (PoC)
4. Разверните Control Plane: `docs/03-cluster-bootstrap.md`
5. Установите CNI (Cilium): `docs/04-cni-setup.md`
6. Настройте Storage (CSI): `docs/05-storage-setup.md`
7. Установите MetalLB: `docs/06-metallb-setup.md`
8. Установите Ingress: `docs/07-ingress-setup.md`

### Этап 2: Production-готовность
9. Настройте мониторинг: `docs/08-observability-setup.md`
10. Настройте backup: `docs/09-backup-setup.md`
11. Запустите тесты: `docs/10-testing-validation.md`

## ⚙️ Размеры ВМ (Dev/PoC)

**Control Plane (3 ноды):**
- 2 vCPU, 8 GB RAM, 80 GB Disk

**Workers (2+ ноды):**
- 4 vCPU, 16 GB RAM, 100 GB Disk

> Для Prod-кластера Control Plane увеличиваются до 4 vCPU / 16 GB RAM.

## 🔐 Безопасность

- NSX-T DFW правила для группы `k8s-nodes`
- SpoofGuard whitelist для VIP и MetalLB IP
- NetworkPolicy в Cilium
- Pod Security Admission (PSA) — TBD уровень
- Регулярные etcd snapshots и Velero backups

## 📊 Критерии успеха

- [ ] Кластер доступен по API VIP
- [ ] Все ноды в статусе **Ready**
- [ ] Динамическое создание PVC работает
- [ ] Service LoadBalancer получает внешние IP
- [ ] Ingress маршрутизирует трафик по host/path
- [ ] Метрики доступны через `kubectl top`
- [ ] Velero/etcd backups проверены

## 🤝 Процесс работы

Этот репозиторий управляется **AI Team Lead** с помощью AI-исполнителей:
1. Team Lead создаёт задачи в виде `.md` инструкций
2. AI-исполнители генерируют манифесты, скрипты, документацию
3. Оператор-человек применяет артефакты к реальной инфраструктуре
4. Валидация и feedback для итераций

**Все манифесты декларативны и воспроизводимы** для развёртывания Prod-кластера.

## 📞 Поддержка

При возникновении проблем:
1. Проверьте `docs/99-troubleshooting.md`
2. Проверьте риски в разделе 10 контекстного документа
3. Валидируйте сетевые настройки (MTU, SpoofGuard, DFW)

## 📝 Лицензия

Внутренний проект для развёртывания корпоративной инфраструктуры.

---

**Последнее обновление:** 2025-10-17
**Версия документа:** 1.0
**Статус:** Подготовка к развёртыванию Dev-кластера
