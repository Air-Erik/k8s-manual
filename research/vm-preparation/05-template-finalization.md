# Финализация VM Template

> **Дата создания:** 2025-01-27
> **Статус:** ✅ COMPLETED
> **AI-агент:** VM Preparation Specialist

---

## Обзор

Этот документ содержит пошаговые инструкции по финализации VM и создания Template в vSphere.

**Цель:** Очистить VM от персональных данных, настроить cloud-init и создать готовый Template.

---

## Предварительные требования

### Состояние VM
- ✅ Ubuntu 24.04 LTS установлена
- ✅ Kubernetes компоненты установлены
- ✅ Системные настройки применены
- ✅ Все компоненты работают

### Важно
**НЕ запускать kubeadm init!** Template должен быть "чистым" без инициализации кластера.

---

## Этап 1: Очистка системы

### 1.1. Очистка логов

```bash
# Очистить системные логи
sudo journalctl --vacuum-time=1d

# Очистить логи приложений
sudo rm -rf /var/log/*.log
sudo rm -rf /var/log/*.log.*
sudo rm -rf /var/log/apt/
sudo rm -rf /var/log/dpkg.log*

# Очистить логи containerd
sudo rm -rf /var/log/containerd.log*

# Очистить логи kubelet (если есть)
sudo rm -rf /var/log/kubelet.log*

# Очистить временные файлы
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -rf /var/cache/apt/archives/*
```

### 1.2. Очистка истории команд

```bash
# Очистить bash history
history -c
rm -f ~/.bash_history

# Очистить history для root
sudo rm -f /root/.bash_history

# Очистить history для k8s-admin
rm -f /home/k8s-admin/.bash_history
```

### 1.3. Очистка SSH данных

```bash
# Удалить SSH host keys (будут пересозданы при первом запуске)
sudo rm -f /etc/ssh/ssh_host_*

# Удалить SSH known_hosts
rm -f ~/.ssh/known_hosts
sudo rm -f /root/.ssh/known_hosts
```

### 1.4. Очистка сетевых настроек

```bash
# Очистить DHCP кэш
sudo rm -f /var/lib/dhcp/dhcpd.leases
sudo rm -f /var/lib/dhcp/dhcpd.leases~

# Очистить сетевые кэши
sudo rm -f /var/lib/NetworkManager/*
```

---

## Этап 2: Сброс системных идентификаторов

### 2.1. Сброс machine-id

```bash
# Удалить machine-id (будет пересоздан при первом запуске)
sudo rm -f /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id

# Создать пустой machine-id (будет заполнен при первом запуске)
sudo touch /etc/machine-id
sudo chmod 444 /etc/machine-id
```

### 2.2. Очистка cloud-init данных

```bash
# Очистить cloud-init logs
sudo rm -rf /var/log/cloud-init*

# Очистить cloud-init cache
sudo rm -rf /var/lib/cloud/instances/*

# Очистить cloud-init seed
sudo rm -rf /var/lib/cloud/seed/*
```

### 2.3. Очистка systemd данных

```bash
# Очистить systemd journal
sudo journalctl --vacuum-time=1s

# Очистить systemd cache
sudo rm -rf /var/lib/systemd/catalog/*
```

---

## Этап 3: Настройка cloud-init

### 3.1. Установка cloud-init

```bash
# Установить cloud-init
sudo apt install -y cloud-init

# Проверить установку
cloud-init --version
# Должна быть: 24.1.x
```

### 3.2. Настройка cloud-init

```bash
# Создать конфигурацию cloud-init
sudo tee /etc/cloud/cloud.cfg <<EOF
# Основная конфигурация cloud-init
users:
  - default
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: [adm, systemd-journal]
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation

# Настройки для Ubuntu
disable_root: true
preserve_hostname: false
manage_etc_hosts: true

# Настройки сети
network:
  config: disabled

# Настройки для Kubernetes
runcmd:
  - systemctl enable containerd kubelet
  - systemctl start containerd
  - echo 'KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"' > /etc/default/kubelet

# Очистка при первом запуске
cloud_init_modules:
  - migrator
  - seed_random
  - bootcmd
  - write-files
  - growpart
  - resizefs
  - disk_setup
  - mounts
  - set-passwords
  - ssh

cloud_final_modules:
  - package-update-upgrade-install
  - runcmd
  - byobu
  - landscape
  - lxd
  - puppet
  - chef
  - salt-minion
  - mcollective
  - disable-ec2-metadata
  - final-message
  - power-state-change

# Настройки для первого запуска
cloud_init_modules:
  - migrator
  - seed_random
  - bootcmd
  - write-files
  - growpart
  - resizefs
  - disk_setup
  - mounts
  - set-passwords
  - ssh

cloud_final_modules:
  - package-update-upgrade-install
  - runcmd
  - byobu
  - landscape
  - lxd
  - puppet
  - chef
  - salt-minion
  - mcollective
  - disable-ec2-metadata
  - final-message
  - power-state-change
EOF
```

### 3.3. Настройка cloud-init для первого запуска

```bash
# Создать скрипт для первого запуска
sudo tee /etc/cloud/cloud-init.d/99-k8s-setup.sh <<EOF
#!/bin/bash
# Скрипт для настройки Kubernetes при первом запуске

# Включить и запустить containerd
systemctl enable containerd
systemctl start containerd

# Включить kubelet (но не запускать до kubeadm init)
systemctl enable kubelet

# Настроить kubelet для containerd
echo 'KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"' > /etc/default/kubelet

# Перезагрузить systemd
systemctl daemon-reload
EOF

# Сделать скрипт исполняемым
sudo chmod +x /etc/cloud/cloud-init.d/99-k8s-setup.sh
```

---

## Этап 4: Финальная очистка

### 4.1. Очистка пакетов

```bash
# Очистить кэш пакетов
sudo apt clean
sudo apt autoremove -y

# Очистить кэш snap (если есть)
sudo rm -rf /var/lib/snapd/cache/*

# Очистить кэш pip (если есть)
sudo rm -rf /root/.cache/pip/*
```

### 4.2. Очистка пользовательских данных

```bash
# Очистить домашние директории
sudo rm -rf /home/k8s-admin/.cache/*
sudo rm -rf /home/k8s-admin/.local/share/Trash/*
sudo rm -rf /root/.cache/*
sudo rm -rf /root/.local/share/Trash/*

# Очистить временные файлы пользователей
sudo rm -rf /home/k8s-admin/tmp/*
sudo rm -rf /root/tmp/*
```

### 4.3. Очистка системных кэшей

```bash
# Очистить кэш приложений
sudo rm -rf /var/cache/apt/archives/*
sudo rm -rf /var/cache/apt/lists/*
sudo rm -rf /var/cache/debconf/*

# Очистить кэш systemd
sudo rm -rf /var/lib/systemd/catalog/*
```

---

## Этап 5: Подготовка к созданию Template

### 5.1. Остановка сервисов

```bash
# Остановить kubelet (если запущен)
sudo systemctl stop kubelet

# Остановить containerd
sudo systemctl stop containerd

# Остановить SSH (временно)
sudo systemctl stop sshd
```

### 5.2. Очистка сетевых интерфейсов

```bash
# Очистить сетевые настройки
sudo rm -f /etc/netplan/*.yaml

# Создать базовую конфигурацию netplan
sudo tee /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens192:
      dhcp4: true
      dhcp6: false
EOF
```

### 5.3. Финальная проверка

```bash
# Проверить, что все сервисы остановлены
sudo systemctl status kubelet containerd sshd
# Должны быть: inactive (dead)

# Проверить размер диска
df -h
# Должен быть: ~80 GB

# Проверить память
free -h
# Должна быть: ~8 GB

# Проверить, что swap отключен
free -h
# Swap должен быть 0
```

---

## Этап 6: Создание Template в vSphere

### 6.1. Подготовка VM

```bash
# Выключить VM
sudo shutdown -h now
```

**В vSphere Client:**

1. **Дождаться полного выключения VM**
2. **Правый клик на VM** → "Template" → "Convert to Template"
3. **Подтвердить создание Template**
4. **Проверить, что Template создан**

### 6.2. Настройка Template metadata

**В vSphere Client:**

1. **Правый клик на Template** → "Edit Settings"
2. **Добавить аннотации:**
   - `k8s.template.version`: `1.0`
   - `k8s.template.os`: `Ubuntu 24.04 LTS`
   - `k8s.template.k8s.version`: `1.31.2`
   - `k8s.template.containerd.version`: `1.7.18`
   - `k8s.template.created`: `2025-01-27`
   - `k8s.template.purpose`: `Kubernetes nodes (CP + Workers)`

3. **Сохранить настройки**

### 6.3. Валидация Template

**Проверка в vSphere:**
- [ ] ✅ Template создан
- [ ] ✅ Metadata добавлена
- [ ] ✅ Размер Template разумный (~80 GB)
- [ ] ✅ Template готов к клонированию

---

## Этап 7: Тестирование Template

### 7.1. Создание тестовой VM

**В vSphere Client:**

1. **Правый клик на Template** → "Deploy Virtual Machine from this Template"
2. **Имя VM:** `k8s-test-node`
3. **Размеры:** 2 vCPU, 8 GB RAM, 80 GB Disk
4. **Сеть:** k8s-zeon-dev-segment
5. **IP:** 10.246.10.250 (временный)

### 7.2. Настройка cloud-init

**При создании VM добавить cloud-init конфигурацию:**

```yaml
#cloud-config
hostname: k8s-test-node
fqdn: k8s-test-node.zeon-dev.local

users:
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation

write_files:
  - path: /etc/netplan/01-static-ip.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [10.246.10.250/24]
            gateway4: 10.246.10.1
            nameservers:
              addresses: [172.17.10.3, 8.8.8.8]

runcmd:
  - netplan apply
  - systemctl enable containerd kubelet
  - systemctl start containerd
```

### 7.3. Валидация тестовой VM

```bash
# Подключиться по SSH
ssh k8s-admin@10.246.10.250

# Проверить hostname
hostname
# Должно быть: k8s-test-node

# Проверить IP
ip addr show
# Должен быть: 10.246.10.250/24

# Проверить Kubernetes компоненты
kubeadm version
kubelet --version
kubectl version --client
containerd --version

# Проверить системные настройки
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
free -h
```

---

## Возможные проблемы и решения

### Проблема 1: VM не клонируется
**Симптомы:** Ошибка при клонировании Template
**Решение:**
- Проверить, что Template полностью выключен
- Проверить права доступа к Template
- Проверить доступное место в datastore

### Проблема 2: cloud-init не работает
**Симптомы:** VM клонируется, но настройки не применяются
**Решение:**
- Проверить синтаксис cloud-init конфигурации
- Проверить логи cloud-init: `sudo journalctl -u cloud-init`
- Проверить, что cloud-init установлен в Template

### Проблема 3: Kubernetes компоненты не работают
**Симптомы:** containerd или kubelet не запускаются
**Решение:**
- Проверить, что все компоненты установлены
- Проверить системные настройки
- Проверить логи: `sudo journalctl -u containerd`

---

## Заключение

**Template готов:**
- ✅ VM очищена от персональных данных
- ✅ cloud-init настроен
- ✅ Template создан в vSphere
- ✅ Тестовая VM работает корректно

**Готовность к использованию:**
- ✅ Template готов для клонирования K8s нод
- ✅ Cloud-init конфигурации готовы
- ✅ Все компоненты работают
- ✅ Система готова для kubeadm init

**Следующий этап:** Создание скриптов автоматизации (scripts/prepare-vm.sh)

---

**Важно:** Template готов для создания Production кластера!
