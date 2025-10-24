# Задание для AI-агента: Kubernetes Cluster Bootstrap

> **Тип задачи:** Практическая инициализация кластера + HA настройка
> **Приоритет:** 🔴 КРИТИЧЕСКИЙ (основа всего проекта)
> **Время:** Ограниченное (практическая задача)
> **Оператор:** Опытный администратор vSphere + начинающий в Kubernetes

---

## Контекст

**Ситуация:**
- ✅ NSX-T настроен (T1 Gateway `T1-k8s-zeon-dev`, сегмент `k8s-zeon-dev-segment`)
- ✅ VM Template готов (Ubuntu 24.04 LTS + K8s компоненты предустановлены)
- ✅ Cloud-init конфигурации созданы для автоматизации клонирования
- 🎯 Нужно инициализировать HA Kubernetes кластер

**Цель проекта:**
Создать работающий Kubernetes кластер с высокой доступностью Control Plane, готовый к установке CNI (Cilium).

**Твоя роль как AI-агента:**
Ты — **эксперт по Kubernetes bootstrap и HA конфигурациям**. Твоя задача:
1. **Создать kubeadm конфигурации** для HA кластера с внешним load balancer
2. **Настроить kube-vip** для API Server VIP (10.246.10.100)
3. **Написать скрипты автоматизации** bootstrap процесса
4. **Создать пошаговые инструкции** для оператора
5. **Подготовить валидационные процедуры** проверки кластера

---

## Исходные данные

### Готовая инфраструктура (из предыдущих этапов):
- **NSX-T Segment:** `k8s-zeon-dev-segment`
- **Subnet:** `10.246.10.0/24`
- **Gateway:** `10.246.10.1`
- **DNS:** Корпоративные (будут указаны оператором)

### IP-план (зафиксирован):
```yaml
# Control Plane Nodes
cp-01: 10.246.10.10
cp-02: 10.246.10.11
cp-03: 10.246.10.12

# Worker Nodes
w-01: 10.246.10.20
w-02: 10.246.10.21

# Kubernetes Services
API_VIP: 10.246.10.100        # kube-vip managed
MetalLB_Pool: 10.246.10.200-220  # для LoadBalancer services (будущее)
```

### Технические параметры:
- **VM Template:** Готов в vSphere (имя будет указано оператором)
- **Kubernetes:** Стабильная версия (установлена в Template)
- **Container Runtime:** containerd (предустановлен)
- **HA Method:** kube-vip для API Server VIP
- **CNI:** Будет установлен на следующем этапе (Cilium)

### Размеры VM:
- **Control Plane:** 2 vCPU, 8 GB RAM, 80 GB Disk
- **Workers:** 4 vCPU, 16 GB RAM, 100 GB Disk

---

## Структура задания

### Этап 1: Планирование и конфигурации
### Этап 2: VM клонирование и подготовка
### Этап 3: Bootstrap первого Control Plane
### Этап 4: HA Control Plane setup
### Этап 5: Worker nodes join
### Этап 6: Валидация и документация

---

## ЭТАП 1: Планирование и конфигурации

**Твоя задача:** Создать все необходимые конфигурации для HA кластера.

### 1.1. Анализ архитектуры и планирование
Создай документ `research/cluster-bootstrap/01-architecture-planning.md`:

**Архитектура кластера:**
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

**Ключевые решения:**
- **HA метод:** kube-vip в ARP mode для API VIP
- **etcd:** Встроенный (stacked topology)
- **Load Balancer:** kube-vip (внутренний)
- **Bootstrap порядок:** cp-01 → cp-02 → cp-03 → workers

**Обоснование выбора kube-vip:**
- Простота настройки для PoC
- Не требует внешнего load balancer
- Хорошо работает в VMware среде
- Поддержка ARP mode для L2 сетей

---

### 1.2. kubeadm конфигурации
Создай документ `research/cluster-bootstrap/02-kubeadm-configs.md`:

**Базовая kubeadm конфигурация для первого CP:**
```yaml
# kubeadm-config-cp01.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.246.10.10
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  kubeletExtraArgs:
    cloud-provider: external
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.31.0  # актуальная версия из Template
clusterName: k8s-zeon-dev
controlPlaneEndpoint: "10.246.10.100:6443"  # kube-vip VIP
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/16"      # для Cilium
  dnsDomain: "cluster.local"
apiServer:
  advertiseAddress: 10.246.10.10
  certSANs:
  - "10.246.10.100"               # VIP
  - "10.246.10.10"                # cp-01
  - "10.246.10.11"                # cp-02
  - "10.246.10.12"                # cp-03
  - "k8s-api.zeon.local"          # DNS name (опционально)
controllerManager:
  extraArgs:
    cloud-provider: external
scheduler:
  extraArgs: {}
etcd:
  local:
    dataDir: "/var/lib/etcd"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
serverTLSBootstrap: true
```

**Конфигурация для дополнительных CP нод:**
```yaml
# kubeadm-config-join-cp.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: "[TOKEN]"              # будет сгенерирован
    apiServerEndpoint: "10.246.10.100:6443"
    caCertHashes: ["[CA_HASH]"]   # будет получен
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  kubeletExtraArgs:
    cloud-provider: external
controlPlane:
  localAPIEndpoint:
    advertiseAddress: "[NODE_IP]"  # 10.246.10.11 или 10.246.10.12
    bindPort: 6443
```

**Конфигурация для Worker нод:**
```yaml
# kubeadm-config-join-worker.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: "[TOKEN]"
    apiServerEndpoint: "10.246.10.100:6443"
    caCertHashes: ["[CA_HASH]"]
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  kubeletExtraArgs:
    cloud-provider: external
```

---

### 1.3. kube-vip конфигурации
Создай документ `research/cluster-bootstrap/03-kube-vip-setup.md`:

**kube-vip манифест для первого CP:**
```yaml
# /etc/kubernetes/manifests/kube-vip.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - args:
    - manager
    env:
    - name: vip_arp
      value: "true"
    - name: port
      value: "6443"
    - name: vip_interface
      value: "ens192"           # интерфейс VM
    - name: vip_cidr
      value: "32"
    - name: cp_enable
      value: "true"
    - name: cp_namespace
      value: kube-system
    - name: vip_ddns
      value: "false"
    - name: svc_enable
      value: "false"            # только для CP, не для services
    - name: vip_address
      value: "10.246.10.100"    # наш VIP
    image: ghcr.io/kube-vip/kube-vip:v0.8.5
    imagePullPolicy: Always
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
    volumeMounts:
    - mountPath: /etc/kubernetes/admin.conf
      name: kubeconfig
  hostAliases:
  - hostnames:
    - kubernetes
    ip: 127.0.0.1
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/admin.conf
    name: kubeconfig
status: {}
```

**Команда генерации kube-vip манифеста:**
```bash
# Для автоматической генерации
sudo ctr image pull ghcr.io/kube-vip/kube-vip:v0.8.5
sudo ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:v0.8.5 vip \
  /kube-vip manifest pod \
  --interface ens192 \
  --address 10.246.10.100 \
  --controlplane \
  --arp \
  --leaderElection | sudo tee /etc/kubernetes/manifests/kube-vip.yaml
```

---

## ЭТАП 2: VM клонирование и подготовка

**Твоя задача:** Создать инструкции по клонированию и подготовке VM.

### 2.1. Инструкции клонирования VM
Создай документ `research/cluster-bootstrap/04-vm-cloning-guide.md`:

**Процедура клонирования:**

1. **Клонирование Control Plane нод:**
```bash
# В vSphere UI или через PowerCLI
# Для каждой CP ноды:

VM Name: cp-01, cp-02, cp-03
Template: [имя VM Template]
Datastore: [выбрать подходящий]
Network: k8s-zeon-dev-segment
CPU: 2 vCPU
RAM: 8 GB
Disk: 80 GB

# Cloud-init customization:
Hostname: cp-01 (cp-02, cp-03)
Static IP: 10.246.10.10 (10.246.10.11, 10.246.10.12)
Netmask: 255.255.255.0
Gateway: 10.246.10.1
DNS: [корпоративные DNS]
```

2. **Клонирование Worker нод:**
```bash
VM Name: w-01, w-02
Template: [имя VM Template]
Network: k8s-zeon-dev-segment
CPU: 4 vCPU
RAM: 16 GB
Disk: 100 GB

# Cloud-init customization:
Hostname: w-01 (w-02)
Static IP: 10.246.10.20 (10.246.10.21)
Netmask: 255.255.255.0
Gateway: 10.246.10.1
DNS: [корпоративные DNS]
```

**Валидация после клонирования:**
```bash
# На каждой VM проверить:
ping 10.246.10.1          # gateway доступен
ping 8.8.8.8              # интернет доступен
systemctl status kubelet  # kubelet готов (но не запущен)
systemctl status containerd # containerd работает
kubeadm version           # kubeadm установлен
```

---

### 2.2. Подготовка нод к bootstrap
Создай документ `research/cluster-bootstrap/05-node-preparation.md`:

**Предварительная настройка на всех нодах:**

```bash
#!/bin/bash
# pre-bootstrap-setup.sh

# 1. Обновление системы (если нужно)
sudo apt update

# 2. Настройка hostname resolution
echo "10.246.10.10 cp-01" | sudo tee -a /etc/hosts
echo "10.246.10.11 cp-02" | sudo tee -a /etc/hosts
echo "10.246.10.12 cp-03" | sudo tee -a /etc/hosts
echo "10.246.10.100 k8s-api" | sudo tee -a /etc/hosts

# 3. Проверка времени (важно для etcd)
sudo timedatectl set-ntp true
timedatectl status

# 4. Проверка firewall (должен быть отключен или настроен)
sudo ufw status
# Если активен - настроить правила или отключить для PoC

# 5. Проверка swap (должен быть отключен)
swapon --show  # должно быть пусто
free -h        # swap должен быть 0

# 6. Загрузка модулей ядра
sudo modprobe br_netfilter
sudo modprobe overlay

# 7. Проверка sysctl настроек
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
# Все должны быть = 1

# 8. Проверка containerd
sudo systemctl status containerd
sudo ctr version

# 9. Проверка kubelet (должен быть остановлен до kubeadm init)
sudo systemctl status kubelet
```

---

## ЭТАП 3: Bootstrap первого Control Plane

**Твоя задача:** Создать детальные инструкции инициализации кластера.

### 3.1. Инициализация первого CP узла
Создай документ `research/cluster-bootstrap/06-first-cp-bootstrap.md`:

**Пошаговая процедура на cp-01:**

1. **Подготовка kube-vip манифеста:**
```bash
# На cp-01 (10.246.10.10)
sudo mkdir -p /etc/kubernetes/manifests

# Создать kube-vip манифест (из этапа 1.3)
sudo tee /etc/kubernetes/manifests/kube-vip.yaml << 'EOF'
[содержимое манифеста из 03-kube-vip-setup.md]
EOF
```

2. **Создание kubeadm конфигурации:**
```bash
# Создать kubeadm config
sudo tee /tmp/kubeadm-config.yaml << 'EOF'
[содержимое из 02-kubeadm-configs.md для cp-01]
EOF
```

3. **Инициализация кластера:**
```bash
# Запуск kubeadm init
sudo kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs

# Сохранить вывод команды! Нужны токены для join
# Пример вывода:
# kubeadm join 10.246.10.100:6443 --token abc123.xyz789 \
#   --discovery-token-ca-cert-hash sha256:hash123... \
#   --control-plane --certificate-key cert-key123...
```

4. **Настройка kubectl для администратора:**
```bash
# Настройка kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Проверка доступности API
kubectl get nodes
kubectl get pods -A
```

5. **Проверка kube-vip:**
```bash
# Проверить что VIP назначен
ip addr show ens192 | grep 10.246.10.100

# Проверить доступность API через VIP
kubectl --server=https://10.246.10.100:6443 get nodes

# Проверить kube-vip pod
kubectl get pods -n kube-system | grep kube-vip
```

**Ожидаемое состояние после инициализации:**
- Кластер инициализирован с одним CP узлом
- kube-vip управляет VIP 10.246.10.100
- API Server доступен через VIP
- etcd запущен и работает
- Узел в состоянии NotReady (нет CNI)

---

### 3.2. Сохранение критических данных
Создай документ `research/cluster-bootstrap/07-bootstrap-tokens.md`:

**Что нужно сохранить после kubeadm init:**

```bash
# 1. Join токен для Control Plane нод
CONTROL_PLANE_JOIN_CMD="kubeadm join 10.246.10.100:6443 --token TOKEN \
  --discovery-token-ca-cert-hash sha256:HASH \
  --control-plane --certificate-key CERT_KEY"

# 2. Join токен для Worker нод
WORKER_JOIN_CMD="kubeadm join 10.246.10.100:6443 --token TOKEN \
  --discovery-token-ca-cert-hash sha256:HASH"

# 3. Certificate key (для CP join)
CERTIFICATE_KEY="CERT_KEY_VALUE"

# 4. CA Certificate hash
CA_CERT_HASH="sha256:HASH_VALUE"

# 5. Bootstrap token
BOOTSTRAP_TOKEN="TOKEN_VALUE"
```

**Команды для получения токенов (если потеряли):**
```bash
# Создать новый bootstrap token
sudo kubeadm token create --print-join-command

# Получить CA cert hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'

# Создать новый certificate key для CP join
sudo kubeadm init phase upload-certs --upload-certs
```

---

## ЭТАП 4: HA Control Plane setup

**Твоя задача:** Создать инструкции присоединения дополнительных CP узлов.

### 4.1. Присоединение второго CP узла
Создай документ `research/cluster-bootstrap/08-second-cp-join.md`:

**Процедура на cp-02 (10.246.10.11):**

1. **Подготовка kube-vip манифеста:**
```bash
# На cp-02
sudo mkdir -p /etc/kubernetes/manifests

# Создать тот же kube-vip манифест
sudo tee /etc/kubernetes/manifests/kube-vip.yaml << 'EOF'
[тот же манифест, что и на cp-01]
EOF
```

2. **Присоединение к кластеру:**
```bash
# Использовать команду из вывода kubeadm init
sudo kubeadm join 10.246.10.100:6443 --token [TOKEN] \
  --discovery-token-ca-cert-hash sha256:[HASH] \
  --control-plane --certificate-key [CERT_KEY]
```

3. **Настройка kubectl:**
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

4. **Валидация:**
```bash
# Проверить узлы
kubectl get nodes

# Проверить etcd members
kubectl exec -n kube-system etcd-cp-01 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Проверить kube-vip на обеих нодах
kubectl get pods -n kube-system | grep kube-vip
```

---

### 4.2. Присоединение третьего CP узла
Создай документ `research/cluster-bootstrap/09-third-cp-join.md`:

**Процедура на cp-03 (10.246.10.12):**

Аналогичная процедура как для cp-02, но с IP 10.246.10.12.

**Финальная валидация HA Control Plane:**
```bash
# Проверить все CP узлы
kubectl get nodes -l node-role.kubernetes.io/control-plane

# Проверить etcd cluster health
kubectl exec -n kube-system etcd-cp-01 -- etcdctl \
  --endpoints=https://10.246.10.10:2379,https://10.246.10.11:2379,https://10.246.10.12:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Тест failover VIP
# Остановить kube-vip на текущем leader
# VIP должен переехать на другой узел
```

---

## ЭТАП 5: Worker nodes join

**Твоя задача:** Создать инструкции присоединения worker узлов.

### 5.1. Присоединение Worker узлов
Создай документ `research/cluster-bootstrap/10-worker-nodes-join.md`:

**Процедура на w-01 и w-02:**

1. **Присоединение к кластеру:**
```bash
# На w-01 (10.246.10.20)
sudo kubeadm join 10.246.10.100:6443 --token [TOKEN] \
  --discovery-token-ca-cert-hash sha256:[HASH]

# На w-02 (10.246.10.21)
sudo kubeadm join 10.246.10.100:6443 --token [TOKEN] \
  --discovery-token-ca-cert-hash sha256:[HASH]
```

2. **Валидация с Control Plane:**
```bash
# С любого CP узла
kubectl get nodes
kubectl get nodes -o wide

# Проверить что все узлы присоединились
kubectl describe nodes

# Узлы будут в состоянии NotReady до установки CNI
```

---

## ЭТАП 6: Валидация и документация

**Твоя задача:** Создать процедуры валидации и финальную документацию.

### 6.1. Комплексная валидация кластера
Создай документ `research/cluster-bootstrap/11-cluster-validation.md`:

**Чек-лист валидации:**

```bash
#!/bin/bash
# cluster-validation.sh

echo "=== Kubernetes Cluster Validation ==="

# 1. Проверка узлов
echo "1. Checking nodes..."
kubectl get nodes -o wide
echo ""

# 2. Проверка системных подов
echo "2. Checking system pods..."
kubectl get pods -A
echo ""

# 3. Проверка etcd health
echo "3. Checking etcd health..."
kubectl exec -n kube-system etcd-cp-01 -- etcdctl \
  --endpoints=https://10.246.10.10:2379,https://10.246.10.11:2379,https://10.246.10.12:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
echo ""

# 4. Проверка API Server через VIP
echo "4. Checking API Server via VIP..."
kubectl --server=https://10.246.10.100:6443 version --short
echo ""

# 5. Проверка kube-vip
echo "5. Checking kube-vip status..."
kubectl get pods -n kube-system | grep kube-vip
echo ""

# 6. Проверка компонентов Control Plane
echo "6. Checking Control Plane components..."
kubectl get componentstatuses 2>/dev/null || echo "componentstatuses deprecated, checking pods instead"
kubectl get pods -n kube-system | grep -E "(kube-apiserver|kube-controller-manager|kube-scheduler|etcd)"
echo ""

# 7. Проверка сертификатов
echo "7. Checking certificate expiration..."
sudo kubeadm certs check-expiration
echo ""

# 8. Тест создания namespace
echo "8. Testing namespace creation..."
kubectl create namespace test-bootstrap --dry-run=client -o yaml | kubectl apply -f -
kubectl get namespace test-bootstrap
kubectl delete namespace test-bootstrap
echo ""

echo "=== Validation Complete ==="
```

**Ожидаемые результаты:**
- 5 узлов в кластере (3 CP + 2 Workers)
- Все узлы в состоянии NotReady (нет CNI - это нормально)
- Все системные поды запущены и работают
- etcd кластер здоров (3 члена)
- API Server доступен через VIP
- kube-vip поды работают на всех CP узлах

---

### 6.2. Troubleshooting guide
Создай документ `research/cluster-bootstrap/12-troubleshooting.md`:

**Частые проблемы и решения:**

1. **kube-vip не назначает VIP:**
```bash
# Проверить интерфейс
ip link show ens192

# Проверить ARP таблицу
arp -a | grep 10.246.10.100

# Проверить логи kube-vip
kubectl logs -n kube-system kube-vip-cp-01

# Решение: проверить interface name в манифесте
```

2. **etcd не может сформировать кластер:**
```bash
# Проверить время на всех узлах
timedatectl status

# Проверить сетевую связность
telnet 10.246.10.10 2379
telnet 10.246.10.11 2379
telnet 10.246.10.12 2379

# Проверить firewall
sudo ufw status
```

3. **kubeadm join fails:**
```bash
# Проверить токен
kubeadm token list

# Создать новый токен
kubeadm token create --print-join-command

# Проверить доступность API
curl -k https://10.246.10.100:6443/version
```

---

### 6.3. Финальная документация
Создай документ `research/cluster-bootstrap/13-final-documentation.md`:

**Сводка созданного кластера:**

```yaml
# Cluster Summary
cluster_name: k8s-zeon-dev
kubernetes_version: v1.31.0
cluster_endpoint: https://10.246.10.100:6443

# Nodes
control_plane_nodes:
  - name: cp-01
    ip: 10.246.10.10
    role: control-plane,etcd
  - name: cp-02
    ip: 10.246.10.11
    role: control-plane,etcd
  - name: cp-03
    ip: 10.246.10.12
    role: control-plane,etcd

worker_nodes:
  - name: w-01
    ip: 10.246.10.20
    role: worker
  - name: w-02
    ip: 10.246.10.21
    role: worker

# Network Configuration
pod_subnet: 10.244.0.0/16
service_subnet: 10.96.0.0/12
api_vip: 10.246.10.100
vip_method: kube-vip

# High Availability
etcd_topology: stacked
etcd_members: 3
api_server_replicas: 3
load_balancer: kube-vip (internal)

# Security
tls_enabled: true
rbac_enabled: true
admission_controllers: default

# Storage
etcd_data_dir: /var/lib/etcd
kubelet_data_dir: /var/lib/kubelet
```

**Готовые команды для администрирования:**
```bash
# Получить kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# Проверить статус кластера
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

# Создать новый join токен
kubeadm token create --print-join-command

# Backup etcd
sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

---

## Дополнительные требования

### Стиль выполнения:
✅ **Делай:**
- Создавай готовые к использованию конфигурации (без TODO)
- Предусматривай обработку ошибок в скриптах
- Документируй все нестандартные решения
- Тестируй команды на совместимость с Ubuntu 24.04

❌ **Не делай:**
- Не используй deprecated API версии
- Не игнорируй безопасность (даже для PoC)
- Не создавай слишком сложные конфигурации

### Особенности работы с оператором:
- Оператор опытный в vSphere, но новичок в Kubernetes
- Все действия будут выполняться на реальной инфраструктуре
- Предпочтение пошаговым инструкциям с объяснениями

---

## Артефакты на выходе

### Обязательные документы:
- [ ] `01-architecture-planning.md` — архитектура и планирование
- [ ] `02-kubeadm-configs.md` — все kubeadm конфигурации
- [ ] `03-kube-vip-setup.md` — настройка kube-vip для VIP
- [ ] `04-vm-cloning-guide.md` — инструкции клонирования VM
- [ ] `05-node-preparation.md` — подготовка нод к bootstrap
- [ ] `06-first-cp-bootstrap.md` — инициализация первого CP
- [ ] `07-bootstrap-tokens.md` — сохранение токенов и ключей
- [ ] `08-second-cp-join.md` — присоединение второго CP
- [ ] `09-third-cp-join.md` — присоединение третьего CP
- [ ] `10-worker-nodes-join.md` — присоединение worker узлов
- [ ] `11-cluster-validation.md` — валидация кластера
- [ ] `12-troubleshooting.md` — решение проблем
- [ ] `13-final-documentation.md` — финальная сводка

### Обязательные скрипты:
- [ ] `scripts/pre-bootstrap-setup.sh` — подготовка нод
- [ ] `scripts/cluster-validation.sh` — валидация кластера
- [ ] `scripts/generate-join-commands.sh` — генерация join команд
- [ ] `scripts/etcd-backup.sh` — backup etcd

### Обязательные конфигурации:
- [ ] `manifests/kubeadm-config-cp01.yaml` — конфиг первого CP
- [ ] `manifests/kubeadm-config-join-cp.yaml` — конфиг join CP
- [ ] `manifests/kubeadm-config-join-worker.yaml` — конфиг join Worker
- [ ] `manifests/kube-vip.yaml` — манифест kube-vip

### Справочные материалы:
- [ ] `cluster-info.yaml` — параметры кластера
- [ ] `node-inventory.md` — инвентарь узлов
- [ ] `network-topology.md` — сетевая топология

---

## Критерии успеха

Задание считается выполненным, когда:

✅ **Кластер инициализирован:**
- 3 Control Plane узла в HA конфигурации
- 2 Worker узла присоединены к кластеру
- etcd кластер работает (3 члена)

✅ **HA настроено:**
- kube-vip управляет API VIP (10.246.10.100)
- API Server доступен через VIP
- Failover VIP работает при отказе узла

✅ **Валидация пройдена:**
- Все системные поды запущены
- Кластер отвечает на команды kubectl
- Можно создавать/удалять ресурсы

✅ **Документация готова:**
- Все инструкции пошаговые и воспроизводимые
- Troubleshooting guide создан
- Параметры кластера задокументированы

✅ **Готовность к CNI:**
- Узлы в состоянии NotReady (ожидают CNI)
- Pod subnet настроен для Cilium (10.244.0.0/16)
- Кластер готов к установке Cilium

---

## Координация с Team Lead

**После завершения задания:**
1. Все артефакты созданы в `research/cluster-bootstrap/`
2. Кластер инициализирован и валидирован
3. Team Lead обновляет PROJECT-PLAN.md (Этап 1.1 → COMPLETED)
4. Переход к Этапу 1.2 (CNI Setup - Cilium)

**Если возникают вопросы:**
Создай файл `research/cluster-bootstrap/QUESTIONS-FOR-TEAM-LEAD.md` с вопросами.

---

**Удачи, AI-агент! Помни: твоя цель — создать стабильный HA Kubernetes кластер готовый к production workloads. Все конфигурации должны быть готовы к использованию "из коробки".**

🚀 **Начинай с Этапа 1 (Планирование и конфигурации)!**
