# Установка Kubernetes компонентов

> **Дата создания:** 2025-01-27
> **Статус:** ✅ COMPLETED
> **AI-агент:** VM Preparation Specialist

---

## Обзор

Этот документ содержит пошаговые инструкции по установке и настройке всех компонентов Kubernetes на базовой VM.

**Цель:** Установить containerd, kubeadm, kubelet, kubectl и настроить систему для работы с Kubernetes.

---

## Предварительные требования

### Состояние VM
- ✅ Ubuntu 24.04 LTS установлена и настроена
- ✅ SSH доступ работает
- ✅ Сетевое подключение работает
- ✅ Система обновлена

### Версии компонентов (из анализа)
- **containerd:** 1.7.18
- **kubeadm/kubelet/kubectl:** 1.31.2
- **runc:** 1.1.12
- **CNI plugins:** 1.4.1

---

## Этап 1: Подготовка системы

### 1.1. Отключение swap

```bash
# Проверить текущее состояние swap
swapon --show
free -h

# Отключить swap
sudo swapoff -a

# Удалить swap из /etc/fstab (чтобы не включался при перезагрузке)
sudo sed -i '/swap/d' /etc/fstab

# Проверить, что swap отключен
free -h
# Swap должен быть 0
```

### 1.2. Настройка sysctl

```bash
# Создать конфигурацию sysctl для Kubernetes
sudo tee /etc/sysctl.d/99-kubernetes.conf <<EOF
# IP forwarding для pod networking
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Bridge netfilter для CNI
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# Дополнительные настройки для производительности
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
EOF

# Применить настройки
sudo sysctl --system

# Проверить настройки
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
# Должны быть: 1
```

### 1.3. Загрузка модулей ядра

```bash
# Загрузить необходимые модули
sudo modprobe overlay
sudo modprobe br_netfilter

# Сделать загрузку постоянной
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

# Проверить загруженные модули
lsmod | grep -E "overlay|br_netfilter"
# Должны быть загружены
```

### 1.4. Настройка systemd cgroup driver

```bash
# Проверить версию systemd
systemctl --version
# Должна быть: 255.x

# Проверить cgroup версию
stat -fc %T /sys/fs/cgroup/
# Должно быть: cgroup2fs (cgroup v2)
```

---

## Этап 2: Установка containerd

### 2.1. Установка зависимостей

```bash
# Обновить пакеты
sudo apt update

# Установить зависимости
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

### 2.2. Добавление репозитория containerd

```bash
# Создать директорию для ключей
sudo mkdir -p /etc/apt/keyrings

# Добавить ключ GPG
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавить репозиторий
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновить список пакетов
sudo apt update
```

### 2.3. Установка containerd

```bash
# Установить containerd
sudo apt install -y containerd.io=1.7.18-1

# Проверить установку
containerd --version
# Должно быть: containerd.io 1.7.18
```

### 2.4. Настройка containerd

```bash
# Создать директорию для конфигурации
sudo mkdir -p /etc/containerd

# Создать базовую конфигурацию
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Настроить systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Настроить sandbox image (если нужно)
sudo sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml

# Включить и запустить containerd
sudo systemctl enable containerd
sudo systemctl start containerd

# Проверить статус
sudo systemctl status containerd
# Должен быть: active (running)
```

### 2.5. Установка runc

```bash
# Установить runc
sudo apt install -y runc

# Проверить версию
runc --version
# Должна быть: 1.1.12
```

### 2.6. Установка CNI plugins

```bash
# Создать директорию для CNI
sudo mkdir -p /opt/cni/bin

# Скачать CNI plugins
CNI_VERSION="v1.4.1"
sudo wget -q --show-progress --https-only --timestamping \
  "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"

# Распаковать
sudo tar -xzf cni-plugins-linux-amd64-${CNI_VERSION}.tgz -C /opt/cni/bin/

# Проверить установку
ls /opt/cni/bin/
# Должны быть: bridge, host-local, loopback, portmap, etc.
```

---

## Этап 3: Установка Kubernetes компонентов

### 3.1. Добавление репозитория Kubernetes

```bash
# Добавить ключ GPG
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Добавить репозиторий
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Обновить список пакетов
sudo apt update
```

### 3.2. Установка Kubernetes пакетов

```bash
# Установить kubeadm, kubelet, kubectl
sudo apt install -y kubelet=1.31.2-1.1 kubeadm=1.31.2-1.1 kubectl=1.31.2-1.1

# Зафиксировать версии (предотвратить автообновление)
sudo apt-mark hold kubelet kubeadm kubectl

# Проверить установку
kubeadm version
kubelet --version
kubectl version --client
# Все должны быть версии 1.31.2
```

### 3.3. Настройка kubelet

```bash
# Создать конфигурацию kubelet
sudo mkdir -p /var/lib/kubelet

# Настроить systemd service для kubelet
sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --runtime-cgroups=/system.slice/containerd.service"
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_SYSTEM_PODS_ARGS \$KUBELET_NETWORK_ARGS \$KUBELET_DNS_ARGS \$KUBELET_AUTHZ_ARGS \$KUBELET_CADVISOR_ARGS \$KUBELET_CERTIFICATE_ARGS \$KUBELET_EXTRA_ARGS
EOF

# Перезагрузить systemd
sudo systemctl daemon-reload

# Включить kubelet (но НЕ запускать до kubeadm init)
sudo systemctl enable kubelet

# Проверить конфигурацию
sudo systemctl status kubelet
# Должен быть: enabled, но не running (это нормально)
```

---

## Этап 4: Валидация установки

### 4.1. Проверка версий компонентов

```bash
# Проверить containerd
containerd --version
# Должно быть: containerd.io 1.7.18

# Проверить runc
runc --version
# Должно быть: 1.1.12

# Проверить CNI plugins
ls /opt/cni/bin/
# Должны быть: bridge, host-local, loopback, portmap, etc.

# Проверить Kubernetes компоненты
kubeadm version
kubelet --version
kubectl version --client
# Все должны быть: 1.31.2
```

### 4.2. Проверка системных настроек

```bash
# Проверить swap
free -h
# Swap должен быть 0

# Проверить sysctl
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
# Должны быть: 1

# Проверить модули
lsmod | grep -E "overlay|br_netfilter"
# Должны быть загружены

# Проверить containerd
sudo systemctl status containerd
# Должен быть: active (running)
```

### 4.3. Проверка готовности к kubeadm

```bash
# Проверить, что kubelet не запущен (это нормально)
sudo systemctl status kubelet
# Должен быть: enabled, но не running

# Проверить конфигурацию kubelet
sudo cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# Должна содержать правильные настройки
```

---

## Этап 5: Подготовка к созданию Template

### 5.1. Очистка временных файлов

```bash
# Очистить кэш пакетов
sudo apt clean

# Очистить логи
sudo journalctl --vacuum-time=1d

# Очистить временные файлы
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
```

### 5.2. Проверка финального состояния

```bash
# Проверить все компоненты
echo "=== System Info ==="
lsb_release -a
uname -r

echo "=== Network Info ==="
ip addr show
ip route show

echo "=== Kubernetes Components ==="
kubeadm version
kubelet --version
kubectl version --client
containerd --version

echo "=== System Settings ==="
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
free -h
```

---

## Возможные проблемы и решения

### Проблема 1: containerd не запускается
**Симптомы:** `systemctl status containerd` показывает ошибки
**Решение:**
```bash
# Проверить конфигурацию
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Перезапустить
sudo systemctl restart containerd

# Проверить логи
sudo journalctl -u containerd
```

### Проблема 2: kubelet не может подключиться к containerd
**Симптомы:** Ошибки в логах kubelet
**Решение:**
```bash
# Проверить socket containerd
ls -la /var/run/containerd/containerd.sock

# Проверить права доступа
sudo chmod 666 /var/run/containerd/containerd.sock
```

### Проблема 3: CNI plugins не найдены
**Симптомы:** Ошибки при запуске kubelet
**Решение:**
```bash
# Проверить установку CNI
ls /opt/cni/bin/

# Переустановить CNI plugins
sudo rm -rf /opt/cni/bin/*
# Повторить установку CNI plugins
```

---

## Заключение

**Kubernetes компоненты установлены:**
- ✅ containerd 1.7.18 настроен и работает
- ✅ kubeadm 1.31.2 установлен
- ✅ kubelet 1.31.2 настроен
- ✅ kubectl 1.31.2 установлен
- ✅ CNI plugins 1.4.1 установлены
- ✅ Системные настройки применены

**Готовность к следующему этапу:**
- ✅ Все компоненты готовы к работе
- ✅ Система настроена для Kubernetes
- ✅ VM готова для создания Template

**Следующий этап:** Финализация Template (05-template-finalization.md)

---

**Важно:** НЕ запускать kubeadm init! Это будет сделано после клонирования VM из Template.
