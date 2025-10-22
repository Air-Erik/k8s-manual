#!/bin/bash
# Скрипт очистки VM для создания Template
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

# Функция подтверждения
confirm() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Операция отменена пользователем"
        exit 0
    fi
}

# Функция очистки логов
cleanup_logs() {
    log "Очистка системных логов..."

    # Очистить journal logs
    sudo journalctl --vacuum-time=1d

    # Очистить логи приложений
    sudo rm -rf /var/log/*.log
    sudo rm -rf /var/log/*.log.*
    sudo rm -rf /var/log/apt/
    sudo rm -rf /var/log/dpkg.log*
    sudo rm -rf /var/log/cloud-init*
    sudo rm -rf /var/log/containerd.log*
    sudo rm -rf /var/log/kubelet.log*

    # Очистить логи systemd
    sudo rm -rf /var/log/journal/*

    # Очистить логи SSH
    sudo rm -rf /var/log/auth.log*
    sudo rm -rf /var/log/secure*

    log_success "Логи очищены"
}

# Функция очистки временных файлов
cleanup_temp_files() {
    log "Очистка временных файлов..."

    # Очистить системные временные файлы
    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*

    # Очистить временные файлы пользователей
    sudo rm -rf /home/k8s-admin/tmp/*
    sudo rm -rf /root/tmp/*

    # Очистить кэш приложений
    sudo rm -rf /var/cache/apt/archives/*
    sudo rm -rf /var/cache/apt/lists/*
    sudo rm -rf /var/cache/debconf/*
    sudo rm -rf /var/cache/snapd/*

    # Очистить кэш пользователей
    sudo rm -rf /home/k8s-admin/.cache/*
    sudo rm -rf /root/.cache/*

    # Очистить кэш systemd
    sudo rm -rf /var/lib/systemd/catalog/*

    log_success "Временные файлы очищены"
}

# Функция очистки истории команд
cleanup_history() {
    log "Очистка истории команд..."

    # Очистить bash history для текущего пользователя
    history -c
    rm -f ~/.bash_history

    # Очистить bash history для всех пользователей
    sudo rm -f /root/.bash_history
    sudo rm -f /home/k8s-admin/.bash_history

    # Очистить zsh history (если есть)
    sudo rm -f /root/.zsh_history
    sudo rm -f /home/k8s-admin/.zsh_history

    # Очистить fish history (если есть)
    sudo rm -f /root/.local/share/fish/fish_history
    sudo rm -f /home/k8s-admin/.local/share/fish/fish_history

    log_success "История команд очищена"
}

# Функция очистки SSH данных
cleanup_ssh() {
    log "Очистка SSH данных..."

    # Удалить SSH host keys
    sudo rm -f /etc/ssh/ssh_host_*

    # Удалить SSH known_hosts
    rm -f ~/.ssh/known_hosts
    sudo rm -f /root/.ssh/known_hosts
    sudo rm -f /home/k8s-admin/.ssh/known_hosts

    # Очистить SSH agent
    sudo rm -rf /tmp/ssh-*

    log_success "SSH данные очищены"
}

# Функция очистки сетевых данных
cleanup_network() {
    log "Очистка сетевых данных..."

    # Очистить DHCP кэш
    sudo rm -f /var/lib/dhcp/dhcpd.leases
    sudo rm -f /var/lib/dhcp/dhcpd.leases~

    # Очистить сетевые кэши
    sudo rm -rf /var/lib/NetworkManager/*

    # Очистить ARP кэш
    sudo ip -s -s neigh flush all

    # Очистить маршруты
    sudo ip route flush cache

    log_success "Сетевые данные очищены"
}

# Функция сброса системных идентификаторов
reset_system_ids() {
    log "Сброс системных идентификаторов..."

    # Удалить machine-id
    sudo rm -f /etc/machine-id
    sudo rm -f /var/lib/dbus/machine-id

    # Создать пустой machine-id
    sudo touch /etc/machine-id
    sudo chmod 444 /etc/machine-id

    # Очистить cloud-init данные
    sudo rm -rf /var/lib/cloud/instances/*
    sudo rm -rf /var/lib/cloud/seed/*

    # Очистить systemd данные
    sudo rm -rf /var/lib/systemd/catalog/*

    log_success "Системные идентификаторы сброшены"
}

# Функция очистки пользовательских данных
cleanup_user_data() {
    log "Очистка пользовательских данных..."

    # Очистить домашние директории
    sudo rm -rf /home/k8s-admin/.cache/*
    sudo rm -rf /home/k8s-admin/.local/share/Trash/*
    sudo rm -rf /root/.cache/*
    sudo rm -rf /root/.local/share/Trash/*

    # Очистить временные файлы пользователей
    sudo rm -rf /home/k8s-admin/tmp/*
    sudo rm -rf /root/tmp/*

    # Очистить историю браузеров (если есть)
    sudo rm -rf /home/k8s-admin/.mozilla/*
    sudo rm -rf /home/k8s-admin/.google-chrome/*
    sudo rm -rf /root/.mozilla/*
    sudo rm -rf /root/.google-chrome/*

    log_success "Пользовательские данные очищены"
}

# Функция очистки пакетов
cleanup_packages() {
    log "Очистка пакетов..."

    # Очистить кэш пакетов
    sudo apt clean
    sudo apt autoremove -y

    # Очистить кэш snap
    sudo rm -rf /var/lib/snapd/cache/*

    # Очистить кэш pip
    sudo rm -rf /root/.cache/pip/*
    sudo rm -rf /home/k8s-admin/.cache/pip/*

    log_success "Пакеты очищены"
}

# Функция остановки сервисов
stop_services() {
    log "Остановка сервисов..."

    # Остановить kubelet (если запущен)
    if sudo systemctl is-active --quiet kubelet; then
        sudo systemctl stop kubelet
        log_success "kubelet остановлен"
    fi

    # Остановить containerd
    if sudo systemctl is-active --quiet containerd; then
        sudo systemctl stop containerd
        log_success "containerd остановлен"
    fi

    # Остановить SSH (временно)
    if sudo systemctl is-active --quiet sshd; then
        sudo systemctl stop sshd
        log_success "SSH остановлен"
    fi

    log_success "Сервисы остановлены"
}

# Функция очистки сетевых настроек
cleanup_network_config() {
    log "Очистка сетевых настроек..."

    # Очистить netplan конфигурации
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

    log_success "Сетевые настройки очищены"
}

# Функция финальной проверки
final_check() {
    log "Финальная проверка..."

    # Проверить размер диска
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    log "Использование диска: ${disk_usage}%"

    # Проверить память
    local memory_usage=$(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    log "Использование памяти: $memory_usage"

    # Проверить, что сервисы остановлены
    if sudo systemctl is-active --quiet kubelet; then
        log_warning "kubelet все еще активен"
    else
        log_success "kubelet остановлен"
    fi

    if sudo systemctl is-active --quiet containerd; then
        log_warning "containerd все еще активен"
    else
        log_success "containerd остановлен"
    fi

    if sudo systemctl is-active --quiet sshd; then
        log_warning "SSH все еще активен"
    else
        log_success "SSH остановлен"
    fi

    log_success "Финальная проверка завершена"
}

# Функция создания отчета
create_report() {
    log "Создание отчета об очистке..."

    local report_file="/tmp/cleanup-report-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$report_file" <<EOF
ОТЧЕТ ОБ ОЧИСТКЕ VM ДЛЯ TEMPLATE
================================
Дата: $(date)
Хост: $(hostname)
Пользователь: $(whoami)

ВЫПОЛНЕННЫЕ ОПЕРАЦИИ:
- Очистка системных логов
- Очистка временных файлов
- Очистка истории команд
- Очистка SSH данных
- Очистка сетевых данных
- Сброс системных идентификаторов
- Очистка пользовательских данных
- Очистка пакетов
- Остановка сервисов
- Очистка сетевых настроек

СОСТОЯНИЕ СИСТЕМЫ:
- Использование диска: $(df -h / | awk 'NR==2 {print $5}')
- Доступное место: $(df -h / | awk 'NR==2 {print $4}')
- Общая память: $(free -h | awk 'NR==2 {print $2}')
- Доступная память: $(free -h | awk 'NR==2 {print $7}')

СЛЕДУЮЩИЕ ШАГИ:
1. Выключить VM: sudo shutdown -h now
2. В vSphere: Convert to Template
3. Создать тестовую VM из Template
4. Проверить работу cloud-init

ОТЧЕТ СОХРАНЕН: $report_file
EOF

    log_success "Отчет создан: $report_file"
}

# Основная функция
main() {
    log "Начало очистки VM для создания Template"

    # Предупреждение
    echo
    echo "=========================================="
    echo "⚠️  ВНИМАНИЕ! ⚠️"
    echo "=========================================="
    echo "Этот скрипт выполнит следующие действия:"
    echo "1. Очистит все логи и временные файлы"
    echo "2. Удалит историю команд и SSH данные"
    echo "3. Сбросит системные идентификаторы"
    echo "4. Остановит все сервисы"
    echo "5. Очистит сетевые настройки"
    echo
    echo "После выполнения VM будет готова для создания Template."
    echo "=========================================="
    echo

    confirm "Вы уверены, что хотите продолжить?"

    cleanup_logs
    cleanup_temp_files
    cleanup_history
    cleanup_ssh
    cleanup_network
    reset_system_ids
    cleanup_user_data
    cleanup_packages
    stop_services
    cleanup_network_config
    final_check
    create_report

    log_success "Очистка VM завершена успешно!"
    echo
    echo "=========================================="
    echo "🎉 VM ГОТОВА ДЛЯ СОЗДАНИЯ TEMPLATE!"
    echo "=========================================="
    echo
    echo "Следующие шаги:"
    echo "1. Выключить VM: sudo shutdown -h now"
    echo "2. В vSphere: Convert to Template"
    echo "3. Создать тестовую VM из Template"
    echo "4. Проверить работу cloud-init"
    echo
    echo "Template будет готов для создания Kubernetes кластера!"
    echo "=========================================="
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Использование: $0 [опции]"
            echo "Опции:"
            echo "  -h, --help     Показать справку"
            echo "  -v, --version  Показать версию"
            echo "  --force        Выполнить без подтверждения"
            exit 0
            ;;
        -v|--version)
            echo "cleanup-vm-for-template.sh версия 1.0"
            exit 0
            ;;
        --force)
            log "Режим принудительного выполнения"
            # Пропустить подтверждение
            main
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
