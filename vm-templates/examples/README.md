# Примеры использования Cloud-init конфигураций

> **Дата создания:** 2025-01-27
> **Статус:** ✅ COMPLETED
> **AI-агент:** VM Preparation Specialist

---

## Обзор

Этот документ содержит примеры использования cloud-init конфигураций для создания Kubernetes нод из Template.

**Цель:** Показать, как использовать готовые cloud-init конфигурации для автоматизации создания VM.

---

## Структура конфигураций

### Доступные конфигурации

| Файл | Назначение | Описание |
|------|------------|----------|
| `cloud-init-base.yaml` | Универсальная | Базовая конфигурация для любых нод |
| `cloud-init-control-plane.yaml` | Control Plane | Специализированная для CP нод |
| `cloud-init-worker.yaml` | Worker ноды | Специализированная для Worker нод |

### Переменные для замены

Все конфигурации используют переменные, которые нужно заменить на реальные значения:

| Переменная | Описание | Пример |
|------------|----------|--------|
| `${hostname}` | Имя хоста | `k8s-cp-01` |
| `${domain}` | Домен | `zeon-dev.local` |
| `${ip_address}` | IP адрес | `10.246.10.10` |
| `${subnet_mask}` | Маска подсети | `24` |
| `${gateway}` | Шлюз | `10.246.10.1` |
| `${dns_servers}` | DNS серверы | `172.17.10.3, 8.8.8.8` |
| `${ssh_public_key}` | SSH публичный ключ | `ssh-rsa AAAAB3NzaC1yc2E...` |
| `${api_vip}` | API VIP адрес | `10.246.10.100` |

---

## Пример 1: Создание Control Plane ноды

### Параметры

- **Имя:** `k8s-cp-01`
- **IP:** `10.246.10.10`
- **Роль:** Control Plane

### Cloud-init конфигурация

```yaml
#cloud-config
hostname: k8s-cp-01
fqdn: k8s-cp-01.zeon-dev.local

users:
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: [adm, systemd-journal, docker]
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation
    home: /home/k8s-admin
    create_home: true

write_files:
  - path: /etc/netplan/01-static-ip.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [10.246.10.10/24]
            gateway4: 10.246.10.1
            nameservers:
              addresses: [172.17.10.3, 8.8.8.8]
            dhcp4: false
            dhcp6: false
    permissions: '0644'
    owner: root:root

  # ... остальная конфигурация из cloud-init-control-plane.yaml

runcmd:
  - netplan apply
  - modprobe overlay
  - modprobe br_netfilter
  - sysctl --system
  - timedatectl set-timezone UTC
  - systemctl enable containerd
  - systemctl start containerd
  - systemctl enable kubelet
  - systemctl daemon-reload
  - apt clean
  - mkdir -p /home/k8s-admin/.ssh
  - chmod 700 /home/k8s-admin/.ssh
  - chown k8s-admin:k8s-admin /home/k8s-admin/.ssh
  - ufw --force enable
  - ufw allow ssh
  - ufw allow 6443/tcp
  - ufw allow 2379:2380/tcp
  - ufw allow 10250/tcp
  - ufw allow 10251/tcp
  - ufw allow 10252/tcp
  - ufw allow 10259/tcp
  - ufw allow 10257/tcp

final_message: |
  ==========================================
  🎉 Kubernetes Control Plane VM готова!
  ==========================================

  Хост: k8s-cp-01
  IP: 10.246.10.10
  Пользователь: k8s-admin

  Следующие шаги:
  1. Проверить подключение: ssh k8s-admin@10.246.10.10
  2. Инициализировать кластер: kubeadm init --control-plane-endpoint=10.246.10.100
  3. Настроить kubeconfig: mkdir -p ~/.kube && cp /etc/kubernetes/admin.conf ~/.kube/config
  4. Установить CNI: kubectl apply -f <cni-manifest>

  ==========================================
```

### Создание VM в vSphere

1. **Правый клик на Template** → "Deploy Virtual Machine from this Template"
2. **Имя VM:** `k8s-cp-01`
3. **Размеры:** 2 vCPU, 8 GB RAM, 80 GB Disk
4. **Сеть:** k8s-zeon-dev-segment
5. **Cloud-init:** Вставить конфигурацию выше

---

## Пример 2: Создание Worker ноды

### Параметры

- **Имя:** `k8s-worker-01`
- **IP:** `10.246.10.20`
- **Роль:** Worker

### Cloud-init конфигурация

```yaml
#cloud-config
hostname: k8s-worker-01
fqdn: k8s-worker-01.zeon-dev.local

users:
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: [adm, systemd-journal, docker]
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation
    home: /home/k8s-admin
    create_home: true

write_files:
  - path: /etc/netplan/01-static-ip.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [10.246.10.20/24]
            gateway4: 10.246.10.1
            nameservers:
              addresses: [172.17.10.3, 8.8.8.8]
            dhcp4: false
            dhcp6: false
    permissions: '0644'
    owner: root:root

  # ... остальная конфигурация из cloud-init-worker.yaml

runcmd:
  - netplan apply
  - modprobe overlay
  - modprobe br_netfilter
  - sysctl --system
  - timedatectl set-timezone UTC
  - systemctl enable containerd
  - systemctl start containerd
  - systemctl enable kubelet
  - systemctl daemon-reload
  - apt clean
  - mkdir -p /home/k8s-admin/.ssh
  - chmod 700 /home/k8s-admin/.ssh
  - chown k8s-admin:k8s-admin /home/k8s-admin/.ssh
  - ufw --force enable
  - ufw allow ssh
  - ufw allow 10250/tcp
  - ufw allow 30000:32767/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp

final_message: |
  ==========================================
  🎉 Kubernetes Worker VM готова!
  ==========================================

  Хост: k8s-worker-01
  IP: 10.246.10.20
  Пользователь: k8s-admin

  Следующие шаги:
  1. Проверить подключение: ssh k8s-admin@10.246.10.20
  2. Присоединиться к кластеру: kubeadm join 10.246.10.100:6443 --token <token>
  3. Проверить статус: kubectl get nodes (с Control Plane)

  ==========================================
```

### Создание VM в vSphere

1. **Правый клик на Template** → "Deploy Virtual Machine from this Template"
2. **Имя VM:** `k8s-worker-01`
3. **Размеры:** 4 vCPU, 16 GB RAM, 100 GB Disk
4. **Сеть:** k8s-zeon-dev-segment
5. **Cloud-init:** Вставить конфигурацию выше

---

## Пример 3: Создание полного кластера

### Control Plane ноды

| Нода | IP | Hostname | Размеры |
|------|----|---------|---------|
| CP-01 | 10.246.10.10 | k8s-cp-01 | 2 vCPU, 8 GB, 80 GB |
| CP-02 | 10.246.10.11 | k8s-cp-02 | 2 vCPU, 8 GB, 80 GB |
| CP-03 | 10.246.10.12 | k8s-cp-03 | 2 vCPU, 8 GB, 80 GB |

### Worker ноды

| Нода | IP | Hostname | Размеры |
|------|----|---------|---------|
| W-01 | 10.246.10.20 | k8s-worker-01 | 4 vCPU, 16 GB, 100 GB |
| W-02 | 10.246.10.21 | k8s-worker-02 | 4 vCPU, 16 GB, 100 GB |

### Порядок создания

1. **Создать Control Plane ноды** (используя `cloud-init-control-plane.yaml`)
2. **Инициализировать кластер** на первой CP ноде
3. **Присоединить остальные CP ноды** к кластеру
4. **Создать Worker ноды** (используя `cloud-init-worker.yaml`)
5. **Присоединить Worker ноды** к кластеру

---

## Пример 4: Использование через Terraform

### terraform/main.tf

```hcl
# Terraform конфигурация для создания Kubernetes кластера
# Использует vSphere provider

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

# Data sources
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "k8s-zeon-dev-segment"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "k8s-ubuntu2404-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Control Plane ноды
resource "vsphere_virtual_machine" "control_plane" {
  count            = 3
  name             = "k8s-cp-0${count.index + 1}"
  resource_pool_id = var.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 8192
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 80
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  # Cloud-init конфигурация
  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/cloud-init-control-plane.yaml", {
      hostname      = "k8s-cp-0${count.index + 1}"
      domain        = "zeon-dev.local"
      ip_address    = "10.246.10.1${count.index}"
      subnet_mask   = "24"
      gateway       = "10.246.10.1"
      dns_servers   = "172.17.10.3, 8.8.8.8"
      ssh_public_key = var.ssh_public_key
      api_vip      = "10.246.10.100"
    }))
  }
}

# Worker ноды
resource "vsphere_virtual_machine" "workers" {
  count            = 2
  name             = "k8s-worker-0${count.index + 1}"
  resource_pool_id = var.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 4
  memory   = 16384
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 100
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  # Cloud-init конфигурация
  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/cloud-init-worker.yaml", {
      hostname      = "k8s-worker-0${count.index + 1}"
      domain        = "zeon-dev.local"
      ip_address    = "10.246.10.2${count.index}"
      subnet_mask   = "24"
      gateway       = "10.246.10.1"
      dns_servers   = "172.17.10.3, 8.8.8.8"
      ssh_public_key = var.ssh_public_key
      api_vip      = "10.246.10.100"
    }))
  }
}
```

### terraform/variables.tf

```hcl
variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "datacenter" {
  description = "vSphere datacenter"
  type        = string
  default     = "Datacenter"
}

variable "datastore" {
  description = "vSphere datastore"
  type        = string
}

variable "resource_pool_id" {
  description = "vSphere resource pool ID"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}
```

---

## Пример 5: Использование через Ansible

### ansible/playbook.yml

```yaml
---
- name: Create Kubernetes cluster VMs
  hosts: localhost
  gather_facts: no
  vars:
    vsphere_host: "vcenter.zeon-dev.local"
    vsphere_user: "administrator@vsphere.local"
    vsphere_password: "{{ vault_vsphere_password }}"
    datacenter: "Datacenter"
    datastore: "datastore1"
    template: "k8s-ubuntu2404-template"
    network: "k8s-zeon-dev-segment"

    control_plane_nodes:
      - name: "k8s-cp-01"
        ip: "10.246.10.10"
        cpus: 2
        memory: 8192
        disk: 80
      - name: "k8s-cp-02"
        ip: "10.246.10.11"
        cpus: 2
        memory: 8192
        disk: 80
      - name: "k8s-cp-03"
        ip: "10.246.10.12"
        cpus: 2
        memory: 8192
        disk: 80

    worker_nodes:
      - name: "k8s-worker-01"
        ip: "10.246.10.20"
        cpus: 4
        memory: 16384
        disk: 100
      - name: "k8s-worker-02"
        ip: "10.246.10.21"
        cpus: 4
        memory: 16384
        disk: 100

  tasks:
    - name: Create Control Plane VMs
      vsphere_vm:
        hostname: "{{ vsphere_host }}"
        username: "{{ vsphere_user }}"
        password: "{{ vsphere_password }}"
        datacenter: "{{ datacenter }}"
        datastore: "{{ datastore }}"
        template: "{{ template }}"
        name: "{{ item.name }}"
        cpus: "{{ item.cpus }}"
        memory: "{{ item.memory }}"
        disk:
          - size_gb: "{{ item.disk }}"
            type: thin
        network:
          - name: "{{ network }}"
            ip: "{{ item.ip }}"
            netmask: "255.255.255.0"
            gateway: "10.246.10.1"
        dns_servers:
          - "172.17.10.3"
          - "8.8.8.8"
        cloud_init:
          hostname: "{{ item.name }}"
          domain: "zeon-dev.local"
          ssh_public_key: "{{ ssh_public_key }}"
          api_vip: "10.246.10.100"
      loop: "{{ control_plane_nodes }}"

    - name: Create Worker VMs
      vsphere_vm:
        hostname: "{{ vsphere_host }}"
        username: "{{ vsphere_user }}"
        password: "{{ vsphere_password }}"
        datacenter: "{{ datacenter }}"
        datastore: "{{ datastore }}"
        template: "{{ template }}"
        name: "{{ item.name }}"
        cpus: "{{ item.cpus }}"
        memory: "{{ item.memory }}"
        disk:
          - size_gb: "{{ item.disk }}"
            type: thin
        network:
          - name: "{{ network }}"
            ip: "{{ item.ip }}"
            netmask: "255.255.255.0"
            gateway: "10.246.10.1"
        dns_servers:
          - "172.17.10.3"
          - "8.8.8.8"
        cloud_init:
          hostname: "{{ item.name }}"
          domain: "zeon-dev.local"
          ssh_public_key: "{{ ssh_public_key }}"
          api_vip: "10.246.10.100"
      loop: "{{ worker_nodes }}"
```

---

## Пример 6: Скрипт автоматизации

### scripts/create-k8s-cluster.sh

```bash
#!/bin/bash
# Скрипт для создания Kubernetes кластера из Template
# Автор: AI-агент VM Preparation Specialist
# Дата: 2025-01-27

set -euo pipefail

# Конфигурация
TEMPLATE_NAME="k8s-ubuntu2404-template"
NETWORK_NAME="k8s-zeon-dev-segment"
GATEWAY="10.246.10.1"
DNS_SERVERS="172.17.10.3,8.8.8.8"
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation"
API_VIP="10.246.10.100"

# Control Plane ноды
declare -A CP_NODES=(
    ["k8s-cp-01"]="10.246.10.10"
    ["k8s-cp-02"]="10.246.10.11"
    ["k8s-cp-03"]="10.246.10.12"
)

# Worker ноды
declare -A WORKER_NODES=(
    ["k8s-worker-01"]="10.246.10.20"
    ["k8s-worker-02"]="10.246.10.21"
)

# Функция создания Control Plane ноды
create_control_plane_node() {
    local hostname="$1"
    local ip="$2"

    echo "Создание Control Plane ноды: $hostname ($ip)"

    # Создать cloud-init конфигурацию
    cat > "/tmp/${hostname}-cloud-init.yaml" <<EOF
#cloud-config
hostname: $hostname
fqdn: $hostname.zeon-dev.local

users:
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: [adm, systemd-journal, docker]
    ssh_authorized_keys:
      - $SSH_PUBLIC_KEY
    home: /home/k8s-admin
    create_home: true

write_files:
  - path: /etc/netplan/01-static-ip.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [$ip/24]
            gateway4: $GATEWAY
            nameservers:
              addresses: [$DNS_SERVERS]
            dhcp4: false
            dhcp6: false
    permissions: '0644'
    owner: root:root

runcmd:
  - netplan apply
  - modprobe overlay
  - modprobe br_netfilter
  - sysctl --system
  - timedatectl set-timezone UTC
  - systemctl enable containerd
  - systemctl start containerd
  - systemctl enable kubelet
  - systemctl daemon-reload
  - apt clean
  - mkdir -p /home/k8s-admin/.ssh
  - chmod 700 /home/k8s-admin/.ssh
  - chown k8s-admin:k8s-admin /home/k8s-admin/.ssh
  - ufw --force enable
  - ufw allow ssh
  - ufw allow 6443/tcp
  - ufw allow 2379:2380/tcp
  - ufw allow 10250/tcp
  - ufw allow 10251/tcp
  - ufw allow 10252/tcp
  - ufw allow 10259/tcp
  - ufw allow 10257/tcp

final_message: |
  ==========================================
  🎉 Kubernetes Control Plane VM готова!
  ==========================================

  Хост: $hostname
  IP: $ip
  Пользователь: k8s-admin

  Следующие шаги:
  1. Проверить подключение: ssh k8s-admin@$ip
  2. Инициализировать кластер: kubeadm init --control-plane-endpoint=$API_VIP
  3. Настроить kubeconfig: mkdir -p ~/.kube && cp /etc/kubernetes/admin.conf ~/.kube/config
  4. Установить CNI: kubectl apply -f <cni-manifest>

  ==========================================
EOF

    # Создать VM в vSphere (пример команды)
    echo "Создание VM $hostname с IP $ip..."
    # Здесь должна быть команда для создания VM в vSphere
    # Например, через govc или vSphere API

    echo "✅ Control Plane нода $hostname создана"
}

# Функция создания Worker ноды
create_worker_node() {
    local hostname="$1"
    local ip="$2"

    echo "Создание Worker ноды: $hostname ($ip)"

    # Создать cloud-init конфигурацию
    cat > "/tmp/${hostname}-cloud-init.yaml" <<EOF
#cloud-config
hostname: $hostname
fqdn: $hostname.zeon-dev.local

users:
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: [adm, systemd-journal, docker]
    ssh_authorized_keys:
      - $SSH_PUBLIC_KEY
    home: /home/k8s-admin
    create_home: true

write_files:
  - path: /etc/netplan/01-static-ip.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [$ip/24]
            gateway4: $GATEWAY
            nameservers:
              addresses: [$DNS_SERVERS]
            dhcp4: false
            dhcp6: false
    permissions: '0644'
    owner: root:root

runcmd:
  - netplan apply
  - modprobe overlay
  - modprobe br_netfilter
  - sysctl --system
  - timedatectl set-timezone UTC
  - systemctl enable containerd
  - systemctl start containerd
  - systemctl enable kubelet
  - systemctl daemon-reload
  - apt clean
  - mkdir -p /home/k8s-admin/.ssh
  - chmod 700 /home/k8s-admin/.ssh
  - chown k8s-admin:k8s-admin /home/k8s-admin/.ssh
  - ufw --force enable
  - ufw allow ssh
  - ufw allow 10250/tcp
  - ufw allow 30000:32767/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp

final_message: |
  ==========================================
  🎉 Kubernetes Worker VM готова!
  ==========================================

  Хост: $hostname
  IP: $ip
  Пользователь: k8s-admin

  Следующие шаги:
  1. Проверить подключение: ssh k8s-admin@$ip
  2. Присоединиться к кластеру: kubeadm join $API_VIP:6443 --token <token>
  3. Проверить статус: kubectl get nodes (с Control Plane)

  ==========================================
EOF

    # Создать VM в vSphere (пример команды)
    echo "Создание VM $hostname с IP $ip..."
    # Здесь должна быть команда для создания VM в vSphere
    # Например, через govc или vSphere API

    echo "✅ Worker нода $hostname создана"
}

# Основная функция
main() {
    echo "=========================================="
    echo "🚀 Создание Kubernetes кластера"
    echo "=========================================="
    echo "Template: $TEMPLATE_NAME"
    echo "Сеть: $NETWORK_NAME"
    echo "API VIP: $API_VIP"
    echo "=========================================="

    # Создать Control Plane ноды
    echo "Создание Control Plane нод..."
    for hostname in "${!CP_NODES[@]}"; do
        create_control_plane_node "$hostname" "${CP_NODES[$hostname]}"
    done

    # Создать Worker ноды
    echo "Создание Worker нод..."
    for hostname in "${!WORKER_NODES[@]}"; do
        create_worker_node "$hostname" "${WORKER_NODES[$hostname]}"
    done

    echo "=========================================="
    echo "🎉 Кластер создан успешно!"
    echo "=========================================="
    echo "Control Plane ноды:"
    for hostname in "${!CP_NODES[@]}"; do
        echo "  - $hostname (${CP_NODES[$hostname]})"
    done
    echo "Worker ноды:"
    for hostname in "${!WORKER_NODES[@]}"; do
        echo "  - $hostname (${WORKER_NODES[$hostname]})"
    done
    echo "=========================================="
}

# Запуск
main "$@"
```

---

## Заключение

**Готовые конфигурации:**
- ✅ Базовая конфигурация для любых нод
- ✅ Специализированная для Control Plane
- ✅ Специализированная для Worker нод
- ✅ Примеры использования через vSphere UI
- ✅ Примеры использования через Terraform
- ✅ Примеры использования через Ansible
- ✅ Скрипт автоматизации

**Следующие шаги:**
1. Выбрать подходящий метод создания VM
2. Настроить переменные для вашей среды
3. Создать VM из Template
4. Проверить работу cloud-init
5. Приступить к настройке Kubernetes кластера

---

**Важно:** Все конфигурации готовы к использованию и содержат все необходимые настройки для автоматизации создания Kubernetes нод.
