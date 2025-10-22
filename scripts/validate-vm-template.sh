#!/bin/bash
# Скрипт валидации VM Template для Kubernetes
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
EXPECTED_K8S_VERSION="1.31.2"
EXPECTED_CONTAINERD_VERSION="1.7.18"
EXPECTED_CNI_VERSION="1.4.1"

# Счетчики
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Функция логирования
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
    ((PASSED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
    ((WARNING_CHECKS++))
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
    ((FAILED_CHECKS++))
}

# Функция проверки
check() {
    local name="$1"
    local command="$2"
    local expected="$3"
    local actual="$4"

    ((TOTAL_CHECKS++))

    if [ "$actual" = "$expected" ]; then
        log_success "$name: $actual"
        return 0
    else
        log_error "$name: ожидается '$expected', получено '$actual'"
        return 1
    fi
}

# Функция проверки с предупреждением
check_warning() {
    local name="$1"
    local command="$2"
    local expected="$3"
    local actual="$4"

    ((TOTAL_CHECKS++))

    if [ "$actual" = "$expected" ]; then
        log_success "$name: $actual"
        return 0
    else
        log_warning "$name: ожидается '$expected', получено '$actual'"
        return 1
    fi
}

# Функция проверки ОС
check_os() {
    log "Проверка операционной системы..."

    if [ ! -f /etc/os-release ]; then
        log_error "Файл /etc/os-release не найден"
        return 1
    fi

    source /etc/os-release

    check "OS ID" "os_id" "ubuntu" "$ID"
    check "OS Version" "os_version" "24.04" "$VERSION_ID"

    # Проверить архитектуру
    local arch=$(uname -m)
    check "Architecture" "arch" "x86_64" "$arch"

    # Проверить версию ядра
    local kernel=$(uname -r)
    if [[ "$kernel" =~ ^6\.8\. ]]; then
        log_success "Kernel version: $kernel"
    else
        log_warning "Kernel version: $kernel (ожидается 6.8.x)"
    fi
}

# Функция проверки системных настроек
check_system_settings() {
    log "Проверка системных настроек..."

    # Проверить swap
    local swap_size=$(free -h | grep Swap | awk '{print $2}')
    if [ "$swap_size" = "0B" ]; then
        log_success "Swap: отключен ($swap_size)"
    else
        log_warning "Swap: $swap_size (рекомендуется отключить)"
    fi

    # Проверить IP forwarding
    local ip_forward=$(sysctl net.ipv4.ip_forward | cut -d' ' -f3)
    check "IP Forwarding" "ip_forward" "1" "$ip_forward"

    # Проверить bridge netfilter
    local bridge_nf=$(sysctl net.bridge.bridge-nf-call-iptables | cut -d' ' -f3)
    check "Bridge netfilter" "bridge_nf" "1" "$bridge_nf"

    # Проверить модули ядра
    if lsmod | grep -q overlay; then
        log_success "Модуль overlay: загружен"
    else
        log_error "Модуль overlay: не загружен"
    fi

    if lsmod | grep -q br_netfilter; then
        log_success "Модуль br_netfilter: загружен"
    else
        log_error "Модуль br_netfilter: не загружен"
    fi
}

# Функция проверки containerd
check_containerd() {
    log "Проверка containerd..."

    # Проверить установку
    if ! command -v containerd &> /dev/null; then
        log_error "containerd: не установлен"
        return 1
    fi

    # Проверить версию
    local containerd_version=$(containerd --version | cut -d' ' -f3)
    check "containerd version" "containerd_version" "$EXPECTED_CONTAINERD_VERSION" "$containerd_version"

    # Проверить статус сервиса
    if sudo systemctl is-active --quiet containerd; then
        log_success "containerd service: активен"
    else
        log_error "containerd service: неактивен"
    fi

    # Проверить конфигурацию
    if [ -f /etc/containerd/config.toml ]; then
        log_success "containerd config: найден"

        # Проверить systemd cgroup driver
        if grep -q "SystemdCgroup = true" /etc/containerd/config.toml; then
            log_success "containerd systemd cgroup: включен"
        else
            log_error "containerd systemd cgroup: отключен"
        fi
    else
        log_error "containerd config: не найден"
    fi
}

# Функция проверки runc
check_runc() {
    log "Проверка runc..."

    if ! command -v runc &> /dev/null; then
        log_error "runc: не установлен"
        return 1
    fi

    local runc_version=$(runc --version | head -n1 | cut -d' ' -f3)
    log_success "runc version: $runc_version"
}

# Функция проверки CNI plugins
check_cni_plugins() {
    log "Проверка CNI plugins..."

    if [ ! -d /opt/cni/bin ]; then
        log_error "CNI directory: не найден"
        return 1
    fi

    # Проверить основные плагины
    local plugins=("bridge" "host-local" "loopback" "portmap" "tuning")
    for plugin in "${plugins[@]}"; do
        if [ -f "/opt/cni/bin/$plugin" ]; then
            log_success "CNI plugin $plugin: найден"
        else
            log_error "CNI plugin $plugin: не найден"
        fi
    done
}

# Функция проверки Kubernetes компонентов
check_kubernetes() {
    log "Проверка Kubernetes компонентов..."

    # Проверить kubeadm
    if ! command -v kubeadm &> /dev/null; then
        log_error "kubeadm: не установлен"
        return 1
    fi

    local kubeadm_version=$(kubeadm version -o short | cut -d'v' -f2)
    check "kubeadm version" "kubeadm_version" "$EXPECTED_K8S_VERSION" "$kubeadm_version"

    # Проверить kubelet
    if ! command -v kubelet &> /dev/null; then
        log_error "kubelet: не установлен"
        return 1
    fi

    local kubelet_version=$(kubelet --version | cut -d' ' -f2)
    check "kubelet version" "kubelet_version" "$EXPECTED_K8S_VERSION" "$kubelet_version"

    # Проверить kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl: не установлен"
        return 1
    fi

    local kubectl_version=$(kubectl version --client -o yaml | grep gitVersion | cut -d' ' -f4 | cut -d'v' -f2)
    check "kubectl version" "kubectl_version" "$EXPECTED_K8S_VERSION" "$kubectl_version"

    # Проверить статус kubelet
    if sudo systemctl is-enabled --quiet kubelet; then
        log_success "kubelet service: включен"
    else
        log_error "kubelet service: не включен"
    fi

    # Проверить конфигурацию kubelet
    if [ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ]; then
        log_success "kubelet config: найден"
    else
        log_error "kubelet config: не найден"
    fi
}

# Функция проверки cloud-init
check_cloud_init() {
    log "Проверка cloud-init..."

    if ! command -v cloud-init &> /dev/null; then
        log_error "cloud-init: не установлен"
        return 1
    fi

    local cloud_init_version=$(cloud-init --version | cut -d' ' -f2)
    log_success "cloud-init version: $cloud_init_version"

    # Проверить конфигурацию
    if [ -f /etc/cloud/cloud.cfg ]; then
        log_success "cloud-init config: найден"
    else
        log_error "cloud-init config: не найден"
    fi
}

# Функция проверки сетевых настроек
check_network() {
    log "Проверка сетевых настроек..."

    # Проверить IP адрес
    local ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1)
    if [ -n "$ip" ]; then
        log_success "IP address: $ip"
    else
        log_warning "IP address: не настроен"
    fi

    # Проверить gateway
    local gateway=$(ip route show | grep default | awk '{print $3}')
    if [ -n "$gateway" ]; then
        log_success "Gateway: $gateway"
    else
        log_warning "Gateway: не настроен"
    fi

    # Проверить DNS
    if [ -f /etc/resolv.conf ] && grep -q nameserver /etc/resolv.conf; then
        log_success "DNS: настроен"
    else
        log_warning "DNS: не настроен"
    fi
}

# Функция проверки SSH
check_ssh() {
    log "Проверка SSH..."

    if sudo systemctl is-active --quiet sshd; then
        log_success "SSH service: активен"
    else
        log_error "SSH service: неактивен"
    fi

    # Проверить конфигурацию SSH
    if [ -f /etc/ssh/sshd_config ]; then
        log_success "SSH config: найден"
    else
        log_error "SSH config: не найден"
    fi
}

# Функция проверки пользователей
check_users() {
    log "Проверка пользователей..."

    # Проверить пользователя k8s-admin
    if id k8s-admin &> /dev/null; then
        log_success "User k8s-admin: существует"
    else
        log_error "User k8s-admin: не существует"
    fi

    # Проверить sudo права
    if sudo -l -U k8s-admin | grep -q "NOPASSWD"; then
        log_success "k8s-admin sudo: настроен"
    else
        log_warning "k8s-admin sudo: не настроен"
    fi
}

# Функция проверки дискового пространства
check_disk_space() {
    log "Проверка дискового пространства..."

    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        log_success "Disk usage: ${disk_usage}%"
    else
        log_warning "Disk usage: ${disk_usage}% (высокое использование)"
    fi

    local available_space=$(df -h / | awk 'NR==2 {print $4}')
    log_success "Available space: $available_space"
}

# Функция проверки памяти
check_memory() {
    log "Проверка памяти..."

    local total_memory=$(free -h | awk 'NR==2 {print $2}')
    local available_memory=$(free -h | awk 'NR==2 {print $7}')

    log_success "Total memory: $total_memory"
    log_success "Available memory: $available_memory"

    if [ "$total_memory" = "8.0Gi" ]; then
        log_success "Memory size: соответствует требованиям"
    else
        log_warning "Memory size: $total_memory (рекомендуется 8GB)"
    fi
}

# Функция проверки готовности к kubeadm
check_kubeadm_readiness() {
    log "Проверка готовности к kubeadm..."

    # Проверить, что kubelet не запущен (это нормально для Template)
    if sudo systemctl is-active --quiet kubelet; then
        log_warning "kubelet: запущен (должен быть остановлен для Template)"
    else
        log_success "kubelet: остановлен (правильно для Template)"
    fi

    # Проверить конфигурацию kubelet
    if [ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ]; then
        log_success "kubelet kubeadm config: найден"
    else
        log_error "kubelet kubeadm config: не найден"
    fi
}

# Функция генерации отчета
generate_report() {
    log "Генерация отчета..."

    echo
    echo "=========================================="
    echo "ОТЧЕТ О ВАЛИДАЦИИ VM TEMPLATE"
    echo "=========================================="
    echo "Дата: $(date)"
    echo "Хост: $(hostname)"
    echo "OS: $(lsb_release -d | cut -d: -f2 | xargs)"
    echo

    echo "СТАТИСТИКА ПРОВЕРОК:"
    echo "  Всего проверок: $TOTAL_CHECKS"
    echo "  ✅ Успешно: $PASSED_CHECKS"
    echo "  ⚠️  Предупреждения: $WARNING_CHECKS"
    echo "  ❌ Ошибки: $FAILED_CHECKS"
    echo

    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $WARNING_CHECKS -eq 0 ]; then
            echo "🎉 РЕЗУЛЬТАТ: Template полностью готов!"
            echo "   Все проверки пройдены успешно."
        else
            echo "✅ РЕЗУЛЬТАТ: Template готов с предупреждениями."
            echo "   Template можно использовать, но рекомендуется исправить предупреждения."
        fi
    else
        echo "❌ РЕЗУЛЬТАТ: Template НЕ готов!"
        echo "   Обнаружены критические ошибки. Template требует доработки."
    fi

    echo
    echo "РЕКОМЕНДАЦИИ:"
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo "1. Исправить все ошибки перед созданием Template"
        echo "2. Повторить валидацию после исправлений"
    fi

    if [ $WARNING_CHECKS -gt 0 ]; then
        echo "1. Рассмотреть исправление предупреждений"
        echo "2. Проверить соответствие требованиям Production"
    fi

    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        echo "1. Template готов для создания в vSphere"
        echo "2. Можно приступать к клонированию тестовых VM"
        echo "3. Рекомендуется создать тестовую VM для финальной проверки"
    fi

    echo "=========================================="
}

# Основная функция
main() {
    log "Начало валидации VM Template для Kubernetes"

    check_os
    check_system_settings
    check_containerd
    check_runc
    check_cni_plugins
    check_kubernetes
    check_cloud_init
    check_network
    check_ssh
    check_users
    check_disk_space
    check_memory
    check_kubeadm_readiness

    generate_report

    if [ $FAILED_CHECKS -eq 0 ]; then
        log_success "Валидация завершена успешно!"
        exit 0
    else
        log_error "Валидация завершена с ошибками!"
        exit 1
    fi
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Использование: $0 [опции]"
            echo "Опции:"
            echo "  -h, --help     Показать справку"
            echo "  -v, --version Показать версию"
            echo "  --quick       Быстрая проверка (только критические компоненты)"
            exit 0
            ;;
        -v|--version)
            echo "validate-vm-template.sh версия 1.0"
            exit 0
            ;;
        --quick)
            log "Режим быстрой проверки не реализован"
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
