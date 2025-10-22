# Создание базовой VM для Template

> **Дата создания:** 2025-01-27
> **Статус:** ✅ COMPLETED
> **AI-агент:** VM Preparation Specialist

---

## Обзор

Этот документ содержит пошаговые инструкции по созданию базовой VM Ubuntu 24.04 LTS для последующего создания Template.

**Цель:** Создать чистую VM с Ubuntu 24.04 LTS, готовую для установки Kubernetes компонентов.

---

## Предварительные требования

### Доступ к инфраструктуре
- ✅ vSphere Client доступен
- ✅ NSX-T сегмент `k8s-zeon-dev-segment` настроен
- ✅ IP-план готов (10.246.10.0/24)
- ✅ Права на создание VM в vSphere

### Ресурсы
- ✅ Ubuntu 24.04 LTS Server ISO загружен в vSphere
- ✅ Достаточно места в datastore
- ✅ SSH ключи оператора готовы

---

## Этап 1: Создание VM в vSphere

### 1.1. Создание новой VM

**В vSphere Client:**

1. **Правый клик на кластере/хосте** → "New Virtual Machine"
2. **Выбрать "Create a new virtual machine"**
3. **Имя VM:** `k8s-template-base`
4. **Выбрать datastore** (рекомендуется тот же, что будет использоваться для k8s нод)
5. **Версия VM:** ESXi 8.0 и выше

### 1.2. Настройки VM

**Hardware Configuration:**

| Параметр | Значение | Обоснование |
|----------|----------|-------------|
| **vCPU** | 2 | Минимальный для Template |
| **RAM** | 8 GB | Минимальный для Template |
| **Disk** | 80 GB (Thin Provisioned) | OS + компоненты + запас |
| **Network** | 1x vNIC | Подключение к k8s-zeon-dev-segment |
| **CD/DVD** | Ubuntu 24.04 LTS ISO | Для установки ОС |

**Дополнительные настройки:**
- **Memory Reservation:** 0 MB (для экономии ресурсов)
- **CPU Reservation:** 0 MHz (для экономии ресурсов)
- **Hot Add Memory:** Отключено
- **Hot Add CPU:** Отключено

### 1.3. Сетевые настройки

**Network Adapter:**
- **Network:** `k8s-zeon-dev-segment`
- **Adapter Type:** VMXNET 3 (рекомендуется)
- **MAC Address:** Автоматически

**Временные настройки для установки:**
- **IP:** 10.246.10.250 (временный, для установки)
- **Gateway:** 10.246.10.1
- **DNS:** 172.17.10.3, 8.8.8.8

---

## Этап 2: Установка Ubuntu 24.04 LTS

### 2.1. Запуск установки

1. **Включить VM** и подключиться к консоли
2. **Выбрать "Install Ubuntu Server"**
3. **Язык:** English
4. **Keyboard:** English (US)

### 2.2. Настройки установки

**Network Configuration:**
```
Hostname: k8s-template-base
Domain: (оставить пустым)
IP Address: 10.246.10.250/24
Gateway: 10.246.10.1
DNS: 172.17.10.3, 8.8.8.8
```

**User Configuration:**
```
Full name: Kubernetes Admin
Username: k8s-admin
Password: [сложный пароль, будет изменён]
Confirm password: [повторить]
```

**Installation Options:**
- ✅ **Install OpenSSH server** (важно!)
- ❌ **Install additional drivers** (не нужно)
- ❌ **Install snaps** (отключить)

**Package Selection:**
- ✅ **Standard system utilities**
- ❌ **Docker** (не устанавливать, будем ставить containerd)
- ❌ **Kubernetes** (не устанавливать, будем ставить вручную)

### 2.3. Завершение установки

1. **Reboot** после установки
2. **Проверить подключение** по SSH
3. **Обновить систему** (но НЕ обновлять ядро автоматически)

---

## Этап 3: Первичная настройка системы

### 3.1. Подключение по SSH

```bash
# С рабочей станции оператора
ssh k8s-admin@10.246.10.250

# Проверить версию ОС
lsb_release -a
# Должно показать: Ubuntu 24.04 LTS
```

### 3.2. Обновление системы

```bash
# Обновить список пакетов
sudo apt update

# Обновить установленные пакеты (БЕЗ обновления ядра)
sudo apt upgrade -y

# НЕ обновлять ядро автоматически
sudo apt-mark hold linux-image-generic linux-headers-generic

# Проверить версию ядра
uname -r
# Должно быть: 6.8.x
```

### 3.3. Установка базовых пакетов

```bash
# Установить необходимые пакеты
sudo apt install -y \
    curl \
    wget \
    vim \
    net-tools \
    htop \
    tree \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release

# Проверить установку
which curl wget vim
```

### 3.4. Настройка SSH

```bash
# Создать директорию для SSH ключей
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Добавить SSH ключ оператора (заменить на реальный ключ)
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... operator@workstation" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Настроить SSH для безопасности
sudo vim /etc/ssh/sshd_config
```

**Настройки SSH (/etc/ssh/sshd_config):**
```
# Отключить root login
PermitRootLogin no

# Отключить password authentication (после добавления ключей)
PasswordAuthentication no

# Включить только ключи
PubkeyAuthentication yes

# Отключить X11 forwarding
X11Forwarding no
```

```bash
# Перезапустить SSH
sudo systemctl restart sshd

# Проверить подключение по ключу
ssh k8s-admin@10.246.10.250
```

### 3.5. Отключение автоматических обновлений

```bash
# Отключить автоматические обновления
sudo systemctl disable unattended-upgrades
sudo systemctl stop unattended-upgrades

# Удалить пакет автоматических обновлений
sudo apt remove -y unattended-upgrades

# Проверить статус
sudo systemctl status unattended-upgrades
# Должно быть: inactive (dead)
```

### 3.6. Настройка timezone

```bash
# Установить UTC timezone
sudo timedatectl set-timezone UTC

# Проверить настройки
timedatectl status
# Должно показать: Time zone: UTC
```

---

## Этап 4: Подготовка к установке Kubernetes

### 4.1. Проверка системных требований

```bash
# Проверить версию ОС
cat /etc/os-release
# Должно быть: Ubuntu 24.04 LTS

# Проверить архитектуру
uname -m
# Должно быть: x86_64

# Проверить доступную память
free -h
# Должно быть: ~8 GB

# Проверить доступное место
df -h
# Должно быть: ~80 GB
```

### 4.2. Настройка hostname (временно)

```bash
# Установить временный hostname
sudo hostnamectl set-hostname k8s-template-base

# Проверить
hostname
# Должно быть: k8s-template-base
```

### 4.3. Проверка сетевого подключения

```bash
# Проверить IP адрес
ip addr show
# Должен быть: 10.246.10.250/24

# Проверить gateway
ip route show
# Должен быть: default via 10.246.10.1

# Проверить DNS
nslookup google.com
# Должен резолвить в IP

# Проверить внешний доступ
ping -c 3 8.8.8.8
# Должен проходить пакеты
```

---

## Этап 5: Валидация готовности

### 5.1. Чек-лист готовности базовой VM

- [ ] ✅ Ubuntu 24.04 LTS установлена
- [ ] ✅ Система обновлена (ядро НЕ обновлено)
- [ ] ✅ SSH доступ работает по ключу
- [ ] ✅ Базовые пакеты установлены
- [ ] ✅ Автообновления отключены
- [ ] ✅ Timezone установлен (UTC)
- [ ] ✅ Сетевое подключение работает
- [ ] ✅ DNS резолвинг работает
- [ ] ✅ Внешний доступ работает

### 5.2. Тест подключения

```bash
# С рабочей станции оператора
ssh k8s-admin@10.246.10.250

# Проверить системную информацию
uname -a
lsb_release -a
free -h
df -h

# Проверить сеть
ping -c 3 8.8.8.8
nslookup kubernetes.io
```

### 5.3. Подготовка к следующему этапу

**VM готова для:**
- ✅ Установки containerd
- ✅ Установки Kubernetes компонентов
- ✅ Системных настроек (sysctl, swap, modules)

---

## Возможные проблемы и решения

### Проблема 1: Не удается подключиться по SSH
**Симптомы:** Connection refused или timeout
**Решение:**
```bash
# Проверить статус SSH
sudo systemctl status sshd

# Перезапустить SSH
sudo systemctl restart sshd

# Проверить firewall
sudo ufw status
```

### Проблема 2: Не работает DNS
**Симптомы:** nslookup не работает
**Решение:**
```bash
# Проверить /etc/resolv.conf
cat /etc/resolv.conf

# Добавить DNS серверы
echo "nameserver 172.17.10.3" | sudo tee -a /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
```

### Проблема 3: Не работает внешний доступ
**Симптомы:** ping 8.8.8.8 не работает
**Решение:**
```bash
# Проверить маршрутизацию
ip route show

# Проверить gateway
ping -c 3 10.246.10.1

# Проверить NAT настройки в NSX-T
```

---

## Заключение

**Базовая VM готова:**
- ✅ Ubuntu 24.04 LTS установлена и настроена
- ✅ Сетевое подключение работает
- ✅ SSH доступ настроен
- ✅ Система готова для установки Kubernetes компонентов

**Следующий этап:** Установка Kubernetes компонентов (04-k8s-installation.md)

---

**Важно:** Не выключать VM! Следующий этап выполняется на той же VM.
