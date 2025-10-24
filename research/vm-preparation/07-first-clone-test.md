# Тестирование первого клона Template

> **Дата создания:** 2025-01-27
> **Статус:** ✅ COMPLETED
> **AI-агент:** VM Preparation Specialist

---

## Обзор

Этот документ содержит процедуру тестирования первого клона VM из Template для проверки готовности к использованию.

**Цель:** Убедиться, что Template работает корректно и готов для создания Production кластера.

---

## Предварительные требования

### Доступ к инфраструктуре
- ✅ Template `k8s-ubuntu2404-template` создан в vSphere
- ✅ NSX-T сегмент `k8s-zeon-dev-segment` настроен
- ✅ IP-план готов (10.246.10.0/24)
- ✅ SSH ключи оператора готовы

### Инструменты для тестирования
- ✅ vSphere Client
- ✅ SSH клиент
- ✅ Скрипт валидации (`scripts/validate-vm-template.sh`)

---

## Этап 1: Подготовка тестовой конфигурации

### 1.1. Параметры тестовой VM

| Параметр | Значение | Обоснование |
|----------|----------|-------------|
| **Имя VM** | `k8s-test-node` | Тестовая нода |
| **IP адрес** | `10.246.10.250` | Временный IP для тестирования |
| **Hostname** | `k8s-test-node` | Соответствует имени VM |
| **Домен** | `zeon-dev.local` | Корпоративный домен |
| **Размеры** | 2 vCPU, 8 GB RAM, 80 GB Disk | Минимальные для тестирования |

### 1.2. Cloud-init конфигурация для теста

Cloud-init metadata (сеть и идентификация):
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

ssh_pwauth: false
disable_root: true

write_files:
  - path: /etc/default/kubelet
    permissions: '0644'
    owner: root:root
    content: |
      KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --runtime-cgroups=/system.slice/containerd.service"
  - path: /etc/sysctl.d/99-kubernetes.conf
    permissions: '0644'
    owner: root:root
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1

runcmd:
  - modprobe overlay
  - modprobe br_netfilter
  - sysctl --system
  - timedatectl set-timezone UTC
  - systemctl enable containerd kubelet
  - systemctl start containerd
  - systemctl daemon-reload
  - apt clean

final_message: |
  ==========================================
  Kubernetes Test VM готова
  ==========================================
  Хост: k8s-test-node
  IP: 10.246.10.250
  Пользователь: k8s-admin
```

---

## Этап 2: Создание тестовой VM

### 2.1. Создание VM в vSphere

**В vSphere Client:**

1. **Правый клик на Template** → "Deploy Virtual Machine from this Template"
2. **Имя VM:** `k8s-test-node`
3. **Размеры:** 2 vCPU, 8 GB RAM, 80 GB Disk
4. **Сеть:** k8s-zeon-dev-segment
5. **Cloud-init:** Вставить конфигурацию выше

### 2.2. Запуск VM

1. **Включить VM** и дождаться полной загрузки
2. **Проверить статус** в vSphere Client
3. **Дождаться завершения cloud-init** (обычно 2-3 минуты)

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

### 3.2. Проверка cloud-init

```bash
# Проверить статус cloud-init
sudo systemctl status cloud-init
# Ожидается: active (running)

# Проверить логи cloud-init
sudo journalctl -u cloud-init
# Ожидается: успешное выполнение всех этапов

# Проверить финальное сообщение
sudo cat /var/lib/cloud/instance/scripts/final-message
# Ожидается: сообщение о готовности VM
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

### 4.2. Проверка результатов

**Ожидаемые результаты:**
- ✅ Все проверки пройдены успешно
- ✅ Версии компонентов соответствуют требованиям
- ✅ Системные настройки применены
- ✅ Сервисы настроены правильно
- ✅ Нет критических ошибок

**Если есть ошибки:**
- ❌ Исправить проблемы в Template
- ❌ Повторить тестирование
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

## Этап 6: Проверка сетевой связности

### 6.1. Проверка DNS

```bash
# Проверить DNS серверы
cat /etc/resolv.conf
# Ожидается: nameserver 172.17.10.3, nameserver 8.8.8.8

# Проверить резолвинг
nslookup google.com
# Ожидается: резолвинг в IP

# Проверить резолвинг Kubernetes
nslookup kubernetes.io
# Ожидается: резолвинг в IP
```

### 6.2. Проверка внешнего доступа

```bash
# Проверить ping интернета
ping -c 3 8.8.8.8
# Ожидается: пакеты проходят

# Проверить доступ к vCenter
curl -k https://<vcenter-ip>
# Ожидается: ответ от vCenter

# Проверить доступ к container registry
curl -I https://registry.k8s.io
# Ожидается: HTTP ответ
```

### 6.3. Проверка внутренней связности

```bash
# Проверить ping gateway
ping -c 3 10.246.10.1
# Ожидается: пакеты проходят

# Проверить ping других нод (если есть)
ping -c 3 10.246.10.10
# Ожидается: пакеты проходят
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
