# Cluster Bootstrap Research

Эта папка содержит исследования, конфигурации и скрипты для инициализации Kubernetes кластера с HA Control Plane.

## Статус

**Текущий этап:** 🟡 Готово к передаче AI-агенту
**Зависимости:** ✅ NSX-T настроен, ✅ VM Template готов

## Главный документ

**[AI-AGENT-TASK.md](./AI-AGENT-TASK.md)** — детальное задание для AI-агента

Содержит:
- 6 этапов работы (планирование → клонирование → bootstrap → HA → workers → валидация)
- 13 документов для создания
- 4+ скрипта автоматизации
- kubeadm и kube-vip конфигурации
- Комплексные валидационные процедуры

## Цель

Создать работающий HA Kubernetes кластер с:
- 3 Control Plane узла (etcd stacked topology)
- 2 Worker узла
- kube-vip для API VIP (10.246.10.100)
- Готовность к установке CNI (Cilium)

## Исходные данные (готовы)

### NSX-T Infrastructure:
- **T1 Gateway:** `T1-k8s-zeon-dev`
- **Segment:** `k8s-zeon-dev-segment` (10.246.10.0/24)
- **Gateway:** `10.246.10.1`

### IP Allocation:
```yaml
Control_Plane:
  cp-01: 10.246.10.10
  cp-02: 10.246.10.11
  cp-03: 10.246.10.12

Workers:
  w-01: 10.246.10.20
  w-02: 10.246.10.21

Services:
  API_VIP: 10.246.10.100
  MetalLB_Pool: 10.246.10.200-220
```

### VM Template:
- **Name:** [будет указано оператором]
- **OS:** Ubuntu 24.04 LTS
- **K8s Components:** Предустановлены (kubeadm, kubelet, kubectl, containerd)
- **Cloud-init:** Готов к автоматизации

## Ожидаемые артефакты

### Документация (`research/cluster-bootstrap/`)
- `01-architecture-planning.md` — архитектура HA кластера
- `02-kubeadm-configs.md` — все kubeadm конфигурации
- `03-kube-vip-setup.md` — настройка kube-vip для API VIP
- `04-vm-cloning-guide.md` — инструкции клонирования VM из Template
- `05-node-preparation.md` — подготовка нод к bootstrap
- `06-first-cp-bootstrap.md` — инициализация первого Control Plane
- `07-bootstrap-tokens.md` — сохранение токенов и ключей
- `08-second-cp-join.md` — присоединение второго CP
- `09-third-cp-join.md` — присоединение третьего CP
- `10-worker-nodes-join.md` — присоединение worker узлов
- `11-cluster-validation.md` — валидация кластера
- `12-troubleshooting.md` — решение проблем
- `13-final-documentation.md` — итоговая сводка

### Скрипты (`scripts/`)
- `pre-bootstrap-setup.sh` — подготовка нод
- `cluster-validation.sh` — валидация кластера
- `generate-join-commands.sh` — генерация join команд
- `etcd-backup.sh` — backup etcd

### Конфигурации (`manifests/`)
- `kubeadm-config-cp01.yaml` — конфиг первого CP
- `kubeadm-config-join-cp.yaml` — конфиг join CP
- `kubeadm-config-join-worker.yaml` — конфиг join Worker
- `kube-vip.yaml` — манифест kube-vip

### Справочные материалы
- `cluster-info.yaml` — параметры кластера
- `node-inventory.md` — инвентарь узлов
- `network-topology.md` — сетевая топология

## Процесс работы

1. **Оператор** передаёт задачу AI-агенту (см. главную инструкцию в корне)
2. **AI-агент** создаёт все документы и конфигурации согласно заданию
3. **Оператор** клонирует VM из Template согласно инструкциям
4. **Оператор** выполняет bootstrap процедуры пошагово
5. **Валидация** — кластер работает и готов к CNI

## Архитектура кластера

```
┌─────────────────────────────────────────────────────────────┐
│                    NSX-T Segment                            │
│                 k8s-zeon-dev-segment                        │
│                   10.246.10.0/24                           │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
         ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
         │  cp-01  │     │  cp-02  │     │  cp-03  │
         │ .10.10  │     │ .10.11  │     │ .10.12  │
         └─────────┘     └─────────┘     └─────────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
                    ┌─────────▼─────────┐
                    │     kube-vip      │
                    │   API VIP: .100   │
                    └───────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
         ┌────▼────┐     ┌────▼────┐
         │  w-01   │     │  w-02   │
         │ .10.20  │     │ .10.21  │
         └─────────┘     └─────────┘
```

## Критерии успеха

- ✅ 3 Control Plane узла в HA конфигурации
- ✅ 2 Worker узла присоединены
- ✅ kube-vip управляет API VIP (10.246.10.100)
- ✅ etcd кластер работает (3 члена)
- ✅ Все системные поды запущены
- ✅ Кластер готов к установке CNI

## Следующий этап

После завершения этой задачи: **Этап 1.2 — CNI Setup (Cilium)**

---

**Начинай с AI-AGENT-TASK.md!**
