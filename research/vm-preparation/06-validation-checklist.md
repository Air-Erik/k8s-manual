# Чек-лист валидации VM Template

> **Дата создания:** 2025-01-27
> **Статус:** ✅ COMPLETED
> **AI-агент:** VM Preparation Specialist

---

## Обзор

Этот документ содержит детальный чек-лист для валидации готовности VM Template для Kubernetes кластера.

**Цель:** Обеспечить, что Template полностью готов для создания Production-ready Kubernetes нод.

---

## Предварительные требования

### Доступ к инфраструктуре
- ✅ vSphere Client доступен
- ✅ Template создан в vSphere
- ✅ SSH доступ к тестовой VM
- ✅ Сетевой доступ к VM

### Инструменты для проверки
- ✅ SSH клиент
- ✅ kubectl (для проверки версий)
- ✅ Скрипт валидации (`scripts/validate-vm-template.sh`)

---

## Этап 1: Проверка Template в vSphere

### 1.1. Проверка создания Template

- [ ] ✅ Template создан в vSphere
- [ ] ✅ Имя Template: `k8s-ubuntu2404-template`
- [ ] ✅ Template находится в правильной папке
- [ ] ✅ Template имеет правильные аннотации
- [ ] ✅ Размер Template разумный (~80 GB)

### 1.2. Проверка метаданных Template

- [ ] ✅ Аннотация `k8s.template.version`: `1.0`
- [ ] ✅ Аннотация `k8s.template.os`: `Ubuntu 24.04 LTS`
- [ ] ✅ Аннотация `k8s.template.k8s.version`: `1.31.2`
- [ ] ✅ Аннотация `k8s.template.containerd.version`: `1.7.18`
- [ ] ✅ Аннотация `k8s.template.created`: `2025-01-27`
- [ ] ✅ Аннотация `k8s.template.purpose`: `Kubernetes nodes (CP + Workers)`

---

## Этап 2: Создание тестовой VM

### 2.1. Параметры тестовой VM

- [ ] ✅ Имя VM: `k8s-test-node`
- [ ] ✅ Размеры: 2 vCPU, 8 GB RAM, 80 GB Disk
- [ ] ✅ Сеть: `k8s-zeon-dev-segment`
- [ ] ✅ IP: `10.246.10.250` (временный)
- [ ] ✅ Cloud-init конфигурация применена

### 2.2. Cloud-init конфигурация для теста

В vCenter используем спецификацию с двумя полями: metadata и user-data.

Cloud-init metadata (сети и базовая идентификация):
```yaml
instance-id: k8s-test-node-001
local-hostname: k8s-test-node

network:
  version: 2
  renderer: networkd
  ethernets:
    nic0:
      match:
        driver: vmxnet3
      addresses:
        - 10.246.10.250/24
      routes:
        - to: default
          via: 10.246.10.1
      nameservers:
        addresses: [172.17.10.3, 8.8.8.8]
```

Cloud-init user-data (пользователи и сервисы):
```yaml
#cloud-config
hostname: k8s-test-node
fqdn: k8s-test-node.zeon-dev.local

users:
  - name: k8s-admin
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash
    groups: [adm, systemd-journal, docker]
    create_home: true
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation

runcmd:
  - timedatectl set-timezone UTC
  - systemctl enable containerd kubelet
  - systemctl start containerd
  - systemctl daemon-reload

final_message: |
  ==========================================
  Kubernetes Test VM готова
  ==========================================
  Хост: k8s-test-node
  IP: 10.246.10.250
  Пользователь: k8s-admin
```

---

## Этап 3: Проверка подключения

### 3.1. SSH подключение

```bash
# Подключиться к тестовой VM
ssh k8s-admin@10.246.10.250

# Проверить hostname
hostname
# Ожидается: k8s-test-node

# Проверить IP адрес
ip addr show
# Ожидается: 10.246.10.250/24

# Проверить gateway
ip route show
# Ожидается: default via 10.246.10.1
```

### 3.2. Сетевая связность

```bash
# Проверить DNS
nslookup google.com
# Ожидается: резолвинг в IP

# Проверить внешний доступ
ping -c 3 8.8.8.8
# Ожидается: пакеты проходят

# Проверить доступ к vCenter
curl -k https://<vcenter-ip>
# Ожидается: ответ от vCenter
```

---

## Этап 4: Автоматическая валидация

### 4.1. Запуск скрипта валидации

```bash
# Скачать скрипт валидации
wget https://raw.githubusercontent.com/your-repo/scripts/validate-vm-template.sh
chmod +x validate-vm-template.sh

# Запустить валидацию
./validate-vm-template.sh
```

### 4.2. Проверка результатов валидации

**Ожидаемые результаты:**
- ✅ Все проверки пройдены успешно
- ✅ Версии компонентов соответствуют требованиям
- ✅ Системные настройки применены
- ✅ Сервисы настроены правильно
- ✅ Нет критических ошибок

**Если есть ошибки:**
- ❌ Исправить проблемы
- ❌ Повторить валидацию
- ❌ Проверить логи

---

## Этап 5: Ручная проверка компонентов

### 5.1. Проверка операционной системы

```bash
# Проверить версию ОС
lsb_release -a
# Ожидается: Ubuntu 24.04 LTS

# Проверить архитектуру
uname -m
# Ожидается: x86_64

# Проверить версию ядра
uname -r
# Ожидается: 6.8.x
```

### 5.2. Проверка системных настроек

```bash
# Проверить swap
free -h
# Ожидается: Swap = 0B

# Проверить IP forwarding
sysctl net.ipv4.ip_forward
# Ожидается: net.ipv4.ip_forward = 1

# Проверить bridge netfilter
sysctl net.bridge.bridge-nf-call-iptables
# Ожидается: net.bridge.bridge-nf-call-iptables = 1

# Проверить модули ядра
lsmod | grep overlay
lsmod | grep br_netfilter
# Ожидается: модули загружены
```

### 5.3. Проверка containerd

```bash
# Проверить версию containerd
containerd --version
# Ожидается: containerd.io 1.7.18

# Проверить статус containerd
sudo systemctl status containerd
# Ожидается: active (running)

# Проверить конфигурацию containerd
sudo cat /etc/containerd/config.toml | grep SystemdCgroup
# Ожидается: SystemdCgroup = true
```

### 5.4. Проверка Kubernetes компонентов

```bash
# Проверить версию kubeadm
kubeadm version
# Ожидается: v1.31.2

# Проверить версию kubelet
kubelet --version
# Ожидается: v1.31.2

# Проверить версию kubectl
kubectl version --client
# Ожидается: v1.31.2

# Проверить статус kubelet
sudo systemctl status kubelet
# Ожидается: enabled, но не running (это нормально)
```

### 5.5. Проверка CNI plugins

```bash
# Проверить установку CNI plugins
ls /opt/cni/bin/
# Ожидается: bridge, host-local, loopback, portmap, tuning, etc.

# Проверить права доступа
ls -la /opt/cni/bin/
# Ожидается: исполняемые файлы
```

---

## Этап 6: Проверка cloud-init

### 6.1. Проверка установки cloud-init

```bash
# Проверить версию cloud-init
cloud-init --version
# Ожидается: 24.1.x

# Проверить статус cloud-init
sudo systemctl status cloud-init
# Ожидается: active (running)

# Проверить логи cloud-init
sudo journalctl -u cloud-init
# Ожидается: успешное выполнение
```

### 6.2. Проверка конфигурации cloud-init

```bash
# Проверить конфигурацию
sudo cat /etc/cloud/cloud.cfg
# Ожидается: правильная конфигурация

# Проверить пользователей
id k8s-admin
# Ожидается: пользователь существует

# Проверить SSH ключи
ls -la /home/k8s-admin/.ssh/
# Ожидается: authorized_keys файл
```

---

## Этап 7: Проверка готовности к kubeadm

### 7.1. Проверка системных требований

```bash
# Проверить, что kubelet не запущен (нормально для Template)
sudo systemctl status kubelet
# Ожидается: enabled, но не running

# Проверить конфигурацию kubelet
sudo cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# Ожидается: правильная конфигурация

# Проверить containerd socket
ls -la /var/run/containerd/containerd.sock
# Ожидается: socket файл существует
```

### 7.2. Тест готовности к kubeadm init

```bash
# Проверить готовность системы
sudo kubeadm config images list
# Ожидается: список образов Kubernetes

# Проверить совместимость версий
sudo kubeadm version
# Ожидается: v1.31.2

# Проверить системные требования
sudo kubeadm init --dry-run
# Ожидается: предварительная проверка без ошибок
```

---

## Этап 8: Проверка производительности

### 8.1. Проверка дискового пространства

```bash
# Проверить использование диска
df -h
# Ожидается: разумное использование (~80 GB)

# Проверить доступное место
df -h / | awk 'NR==2 {print $4}'
# Ожидается: достаточно места для работы
```

### 8.2. Проверка памяти

```bash
# Проверить общую память
free -h
# Ожидается: ~8 GB

# Проверить доступную память
free -h | awk 'NR==2 {print $7}'
# Ожидается: достаточно для Kubernetes
```

### 8.3. Проверка CPU

```bash
# Проверить количество CPU
nproc
# Ожидается: 2

# Проверить загрузку CPU
top -bn1 | grep "Cpu(s)"
# Ожидается: низкая загрузка
```

---

## Этап 9: Проверка безопасности

### 9.1. Проверка SSH

```bash
# Проверить конфигурацию SSH
sudo cat /etc/ssh/sshd_config | grep -E "PermitRootLogin|PasswordAuthentication"
# Ожидается: PermitRootLogin no, PasswordAuthentication no

# Проверить подключение по ключу
ssh k8s-admin@10.246.10.250
# Ожидается: подключение без пароля
```

### 9.2. Проверка firewall

```bash
# Проверить статус firewall
sudo ufw status
# Ожидается: активен с правильными правилами

# Проверить правила firewall
sudo ufw status numbered
# Ожидается: правила для SSH и Kubernetes портов
```

---

## Этап 10: Финальная проверка

### 10.1. Проверка всех компонентов

```bash
# Запустить полную проверку
./scripts/validate-vm-template.sh

# Проверить отчет
cat /tmp/cleanup-report-*.txt
# Ожидается: отчет об успешной валидации
```

### 10.2. Проверка готовности к Production

- [ ] ✅ Все компоненты установлены и настроены
- [ ] ✅ Версии соответствуют требованиям
- [ ] ✅ Системные настройки применены
- [ ] ✅ Сетевая связность работает
- [ ] ✅ Cloud-init готов к использованию
- [ ] ✅ Безопасность настроена
- [ ] ✅ Производительность соответствует требованиям
- [ ] ✅ Нет критических ошибок

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

### Проблема 4: Сетевая связность не работает
**Симптомы:** Не удается подключиться по SSH или ping
**Решение:**
- Проверить настройки сети в vSphere
- Проверить конфигурацию netplan
- Проверить настройки NSX-T

---

## Заключение

**Template готов, если:**
- ✅ Все проверки пройдены успешно
- ✅ Нет критических ошибок
- ✅ Компоненты работают корректно
- ✅ Cloud-init готов к использованию
- ✅ Система готова для kubeadm

**Следующие шаги:**
1. Template готов для создания Production кластера
2. Можно создавать Control Plane и Worker ноды
3. Приступать к настройке Kubernetes кластера

---

**Важно:** Все проверки должны быть пройдены успешно перед использованием Template в Production!
