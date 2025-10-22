#!/bin/bash
# Скрипт подготовки VM для Kubernetes Template
# Автор: AI-агент VM Preparation Specialist
# Дата: 2025-01-27
# Версия: 1.0

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
K8S_VERSION="1.31.2"
CONTAINERD_VERSION="1.7.18"
CNI_VERSION="v1.4.1"
RUNC_VERSION="1.1.12"

# Функция логирования
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
}

# Функция проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        log_error "Ошибка выполнения команды: $1"
        exit 1
    fi
}

# Функция проверки ОС
check_os() {
    log "Проверка операционной системы..."

    if [ ! -f /etc/os-release ]; then
        log_error "Файл /etc/os-release не найден"
        exit 1
    fi

    source /etc/os-release

    if [ "$ID" != "ubuntu" ]; then
        log_error "Поддерживается только Ubuntu. Обнаружена ОС: $ID"
        exit 1
    fi

    if [ "$VERSION_ID" != "24.04" ]; then
        log_error "Поддерживается только Ubuntu 24.04. Обнаружена версия: $VERSION_ID"
        exit 1
    fi

    log_success "ОС проверена: Ubuntu $VERSION_ID"
}

# Функция проверки прав доступа
check_permissions() {
    log "Проверка прав доступа..."

    if [ "$EUID" -eq 0 ]; then
        log_error "Не запускайте скрипт от root. Используйте sudo для отдельных команд."
        exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
        log_error "Требуются права sudo. Запустите: sudo -v"
        exit 1
    fi

    log_success "Права доступа проверены"
}

# Функция отключения swap
disable_swap() {
    log "Отключение swap..."

    # Проверить текущее состояние swap
    if [ "$(swapon --show | wc -l)" -gt 0 ]; then
        log "Отключение активного swap..."
        sudo swapoff -a
    fi

    # Удалить swap из /etc/fstab
    if grep -q swap /etc/fstab; then
        log "Удаление swap из /etc/fstab..."
        sudo sed -i '/swap/d' /etc/fstab
    fi

    # Проверить, что swap отключен
    if [ "$(free -h | grep Swap | awk '{print $2}')" != "0B" ]; then
        log_warning "Swap не полностью отключен. Проверьте вручную."
    else
        log_success "Swap отключен"
    fi
}

# Функция настройки sysctl
configure_sysctl() {
    log "Настройка sysctl параметров..."

    # Создать конфигурацию sysctl
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
    if [ "$(sysctl net.ipv4.ip_forward)" != "net.ipv4.ip_forward = 1" ]; then
        log_error "IP forwarding не настроен"
        exit 1
    fi

    if [ "$(sysctl net.bridge.bridge-nf-call-iptables)" != "net.bridge.bridge-nf-call-iptables = 1" ]; then
        log_error "Bridge netfilter не настроен"
        exit 1
    fi

    log_success "sysctl параметры настроены"
}

# Функция загрузки модулей ядра
load_kernel_modules() {
    log "Загрузка модулей ядра..."

    # Загрузить модули
    sudo modprobe overlay
    sudo modprobe br_netfilter

    # Сделать загрузку постоянной
    sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

    # Проверить загруженные модули
    if ! lsmod | grep -q overlay; then
        log_error "Модуль overlay не загружен"
        exit 1
    fi

    if ! lsmod | grep -q br_netfilter; then
        log_error "Модуль br_netfilter не загружен"
        exit 1
    fi

    log_success "Модули ядра загружены"
}

# Функция установки containerd
install_containerd() {
    log "Установка containerd $CONTAINERD_VERSION..."

    # Обновить пакеты
    sudo apt update

    # Установить зависимости
    sudo apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Добавить ключ GPG Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Добавить репозиторий Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Обновить список пакетов
    sudo apt update

    # Установить containerd
    sudo apt install -y containerd.io=$CONTAINERD_VERSION-1

    # Создать конфигурацию containerd
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml

    # Настроить systemd cgroup driver
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

    # Настроить sandbox image
    sudo sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml

    # Включить и запустить containerd
    sudo systemctl enable containerd
    sudo systemctl start containerd

    # Проверить версию
    local installed_version=$(containerd --version | cut -d' ' -f3)
    if [ "$installed_version" != "$CONTAINERD_VERSION" ]; then
        log_error "Неверная версия containerd: $installed_version (ожидается: $CONTAINERD_VERSION)"
        exit 1
    fi

    log_success "containerd $CONTAINERD_VERSION установлен"
}

# Функция установки runc
install_runc() {
    log "Установка runc..."

    # Установить runc
    sudo apt install -y runc

    # Проверить установку
    if ! command -v runc &> /dev/null; then
        log_error "runc не установлен"
        exit 1
    fi

    log_success "runc установлен"
}

# Функция установки CNI plugins
install_cni_plugins() {
    log "Установка CNI plugins $CNI_VERSION..."

    # Создать директорию для CNI
    sudo mkdir -p /opt/cni/bin

    # Скачать CNI plugins
    sudo wget -q --show-progress --https-only --timestamping \
        "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"

    # Распаковать
    sudo tar -xzf cni-plugins-linux-amd64-${CNI_VERSION}.tgz -C /opt/cni/bin/

    # Очистить архив
    sudo rm -f cni-plugins-linux-amd64-${CNI_VERSION}.tgz

    # Проверить установку
    if [ ! -f /opt/cni/bin/bridge ]; then
        log_error "CNI plugins не установлены"
        exit 1
    fi

    log_success "CNI plugins $CNI_VERSION установлены"
}

# Функция установки Kubernetes компонентов
install_kubernetes() {
    log "Установка Kubernetes $K8S_VERSION..."

    # Добавить ключ GPG Kubernetes
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Добавить репозиторий Kubernetes
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # Обновить список пакетов
    sudo apt update

    # Установить Kubernetes компоненты
    sudo apt install -y kubelet=$K8S_VERSION-1.1 kubeadm=$K8S_VERSION-1.1 kubectl=$K8S_VERSION-1.1

    # Зафиксировать версии
    sudo apt-mark hold kubelet kubeadm kubectl

    # Проверить установку
    local kubeadm_version=$(kubeadm version -o short)
    local kubelet_version=$(kubelet --version | cut -d' ' -f2)
    local kubectl_version=$(kubectl version --client -o yaml | grep gitVersion | cut -d' ' -f4)

    if [ "$kubeadm_version" != "v$K8S_VERSION" ]; then
        log_error "Неверная версия kubeadm: $kubeadm_version (ожидается: v$K8S_VERSION)"
        exit 1
    fi

    log_success "Kubernetes $K8S_VERSION установлен"
}

# Функция настройки kubelet
configure_kubelet() {
    log "Настройка kubelet..."

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

    # Включить kubelet (но не запускать до kubeadm init)
    sudo systemctl enable kubelet

    log_success "kubelet настроен"
}

# Функция финальной очистки
cleanup_for_template() {
    log "Очистка системы для Template..."

    # Очистить кэш пакетов
    sudo apt clean
    sudo apt autoremove -y

    # Очистить логи
    sudo journalctl --vacuum-time=1d

    # Очистить временные файлы
    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*

    # Очистить историю команд
    history -c
    rm -f ~/.bash_history
    sudo rm -f /root/.bash_history

    # Очистить SSH host keys
    sudo rm -f /etc/ssh/ssh_host_*

    # Сбросить machine-id
    sudo rm -f /etc/machine-id
    sudo rm -f /var/lib/dbus/machine-id
    sudo touch /etc/machine-id
    sudo chmod 444 /etc/machine-id

    log_success "Система очищена для Template"
}

# Функция проверки готовности
validate_installation() {
    log "Проверка готовности системы..."

    # Проверить версии компонентов
    local containerd_version=$(containerd --version | cut -d' ' -f3)
    local kubeadm_version=$(kubeadm version -o short)
    local kubelet_version=$(kubelet --version | cut -d' ' -f2)
    local kubectl_version=$(kubectl version --client -o yaml | grep gitVersion | cut -d' ' -f4)

    log "Версии компонентов:"
    log "  containerd: $containerd_version"
    log "  kubeadm: $kubeadm_version"
    log "  kubelet: $kubelet_version"
    log "  kubectl: $kubectl_version"

    # Проверить системные настройки
    local ip_forward=$(sysctl net.ipv4.ip_forward | cut -d' ' -f3)
    local bridge_nf=$(sysctl net.bridge.bridge-nf-call-iptables | cut -d' ' -f3)

    if [ "$ip_forward" != "1" ]; then
        log_error "IP forwarding не включен"
        exit 1
    fi

    if [ "$bridge_nf" != "1" ]; then
        log_error "Bridge netfilter не включен"
        exit 1
    fi

    # Проверить swap
    local swap_size=$(free -h | grep Swap | awk '{print $2}')
    if [ "$swap_size" != "0B" ]; then
        log_warning "Swap не полностью отключен: $swap_size"
    fi

    # Проверить модули
    if ! lsmod | grep -q overlay; then
        log_error "Модуль overlay не загружен"
        exit 1
    fi

    if ! lsmod | grep -q br_netfilter; then
        log_error "Модуль br_netfilter не загружен"
        exit 1
    fi

    # Проверить containerd
    if ! sudo systemctl is-active --quiet containerd; then
        log_error "containerd не запущен"
        exit 1
    fi

    log_success "Система готова для Kubernetes"
}

# Основная функция
main() {
    log "Начало подготовки VM для Kubernetes Template"
    log "Версии: K8s=$K8S_VERSION, containerd=$CONTAINERD_VERSION, CNI=$CNI_VERSION"

    check_os
    check_permissions
    disable_swap
    configure_sysctl
    load_kernel_modules
    install_containerd
    install_runc
    install_cni_plugins
    install_kubernetes
    configure_kubelet
    validate_installation
    cleanup_for_template

    log_success "Подготовка VM завершена успешно!"
    log "Следующие шаги:"
    log "1. Выключить VM: sudo shutdown -h now"
    log "2. В vSphere: Convert to Template"
    log "3. Создать тестовую VM из Template"
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Использование: $0 [опции]"
            echo "Опции:"
            echo "  -h, --help     Показать справку"
            echo "  -v, --version  Показать версию"
            echo "  --dry-run      Показать команды без выполнения"
            exit 0
            ;;
        -v|--version)
            echo "prepare-vm.sh версия 1.0"
            exit 0
            ;;
        --dry-run)
            log "Режим dry-run не реализован"
            exit 0
            ;;
        *)
            log_error "Неизвестная опция: $1"
            exit 1
            ;;
    esac
    shift
done

# Запуск основной функции
main "$@"
