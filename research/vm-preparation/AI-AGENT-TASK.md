# Задание для AI-агента: VM Template Preparation для Kubernetes

> **Тип задачи:** Практическая подготовка + Создание скриптов
> **Приоритет:** 🟡 ВЫСОКИЙ (следующий этап после NSX)
> **Время:** Ограниченное (практическая задача)
> **Оператор:** Опытный администратор vSphere

---

## Контекст

**Ситуация:**
- NSX-T настроен ✅ (T1 Gateway `T1-k8s-zeon-dev`, сегмент `k8s-zeon-dev-segment`)
- IP-план зафиксирован ✅ (`10.246.10.0/24`, CP: 10-12, Workers: 20-30, VIP: 100)
- Нужно подготовить VM Template для клонирования Kubernetes нод

**Цель проекта:**
Создать готовый к использованию VM Template Ubuntu 24.04 LTS с предустановленными компонентами Kubernetes.

**Твоя роль как AI-агента:**
Ты — **практический консультант и автоматизатор**. Твоя задача:
1. **Создать пошаговые инструкции** по подготовке VM Template
2. **Написать скрипты автоматизации** установки и настройки
3. **Подготовить Cloud-init конфигурации** для быстрого клонирования
4. **Создать валидационные чек-листы** проверки готовности Template

---

## Исходные данные

### Из NSX-T конфигурации:
- **Segment:** `k8s-zeon-dev-segment`
- **Subnet:** `10.246.10.0/24`
- **Gateway:** `10.246.10.1`
- **DNS:** Корпоративные или публичные (будет указано оператором)

### Требования к компонентам:
- **ОС:** Ubuntu 24.04 LTS (Server, minimal)
- **Kubernetes:** 1.34.x (но проверить доступность! Может быть 1.31.x)
- **Container Runtime:** containerd (latest stable)
- **Network:** Static IP configuration через cloud-init
- **Disk:** 80-100 GB (thin provisioned)

### Размеры VM (из контекста):
**Control Plane:** 2 vCPU, 8 GB RAM, 80 GB Disk
**Workers:** 4 vCPU, 16 GB RAM, 100 GB Disk

---

## Структура задания

### Этап 1: Анализ требований и подготовка
### Этап 2: Создание пошаговых инструкций
### Этап 3: Создание скриптов автоматизации
### Этап 4: Cloud-init конфигурации
### Этап 5: Валидация и документация

---

## ЭТАП 1: Анализ требований и подготовка

**Твоя задача:** Проанализировать требования и подготовить план действий.

### 1.1. Анализ версий и совместимости
Создай документ `research/vm-preparation/01-version-analysis.md`:

**Проверь доступность:**
- **Kubernetes 1.34.x:** доступна ли? Если нет → рекомендуй последнюю stable (1.31.x)
- **containerd:** последняя версия совместимая с выбранной версией K8s
- **Ubuntu 24.04 LTS:** подтверди совместимость с выбранными версиями

**Создай таблицу:**
```markdown
| Компонент | Рекомендуемая версия | Источник установки | Совместимость |
|-----------|---------------------|-------------------|---------------|
| Ubuntu | 24.04 LTS | ISO/OVA | ✅ |
| Kubernetes | 1.31.x (если 1.34 недоступна) | apt.kubernetes.io | ✅ |
| containerd | x.x.x | Ubuntu repos / containerd.io | ✅ |
| ... | ... | ... | ... |
```

**Важные моменты:**
- Если K8s 1.34 недоступна — предложи альтернативу и обнови контекстный документ
- Убедись в совместимости всех компонентов
- Укажи официальные источники установки

---

### 1.2. Планирование Template структуры
Создай документ `research/vm-preparation/02-template-strategy.md`:

**Варианты архитектуры Template:**
1. **Единый Template** для всех типов нод (рекомендуется для PoC)
2. **Раздельные Templates** для CP и Workers (для Production)

**Рекомендация с обоснованием:**
- Для Dev-кластера: единый Template (проще поддержка)
- Размеры будут задаваться при клонировании VM
- Специфичные настройки — через cloud-init

**Plan:**
- Base Template: `k8s-ubuntu2404-template`
- Содержит: OS + все K8s компоненты + базовые настройки
- НЕ содержит: специфичные IP, hostname, роли

---

## ЭТАП 2: Создание пошаговых инструкций

**Твоя задача:** Создать детальные, воспроизводимые инструкции.

### 2.1. Создание базовой VM
Создай документ `research/vm-preparation/03-base-vm-creation.md`:

**Пошаговая инструкция:**
1. **Создание VM в vSphere:**
   - Настройки VM (vCPU, RAM, Disk для Template)
   - Подключение к `k8s-zeon-dev-segment`
   - Временный IP для установки (например, 10.246.10.250)

2. **Установка Ubuntu 24.04:**
   - Настройки установщика (minimal install, no snap)
   - Пользователь: `k8s-admin` (или другой стандартный)
   - SSH access: yes
   - Обновления: manual (контролируемые)

3. **Первичная настройка:**
   - SSH ключи для доступа
   - Базовые пакеты (curl, wget, vim, etc.)
   - Отключение автообновлений

**Формат:** Подробные шаги с командами и скриншотами (по необходимости).

---

### 2.2. Установка Kubernetes компонентов
Создай документ `research/vm-preparation/04-k8s-installation.md`:

**Структура:**
1. **Подготовка системы:**
   - Отключение swap
   - Настройка sysctl (ip_forward, bridge-nf-call-iptables)
   - Модули ядра (overlay, br_netfilter)

2. **Установка containerd:**
   - Установка из официальных источников
   - Конфигурация (`/etc/containerd/config.toml`)
   - Настройка systemd cgroup driver

3. **Установка Kubernetes компонентов:**
   - Добавление apt репозитория
   - Установка kubeadm, kubelet, kubectl (фиксированные версии)
   - Hold packages (предотвращение автообновления)

4. **Настройка kubelet:**
   - Конфигурация systemd service
   - Настройки для cloud-init integration

**Важно:** Все команды должны быть готовы к автоматизации в скрипте.

---

### 2.3. Финализация Template
Создай документ `research/vm-preparation/05-template-finalization.md`:

**Подготовка к Template:**
1. **Очистка системы:**
   - Очистка логов, history, temporary files
   - Сброс machine-id
   - Очистка SSH host keys (будут regenerated)

2. **Cloud-init подготовка:**
   - Установка cloud-init
   - Базовая конфигурация
   - Удаление instance-specific данных

3. **Создание Template в vSphere:**
   - Shutdown VM
   - Convert to Template
   - Настройка Template metadata

**Чек-лист готовности:**
- [ ] Все K8s компоненты установлены
- [ ] Система очищена от персональных данных
- [ ] Cloud-init готов к первому запуску
- [ ] Template создан в vSphere

---

## ЭТАП 3: Создание скриптов автоматизации

**Твоя задача:** Написать скрипты для автоматизации процесса.

### 3.1. Основной скрипт подготовки
Создай файл `scripts/prepare-vm.sh`:

**Функции скрипта:**
- Проверка ОС и прав доступа
- Отключение swap
- Настройка sysctl
- Установка containerd
- Установка Kubernetes компонентов
- Настройка systemd services
- Финальная очистка

**Структура:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration
K8S_VERSION="1.31"  # или актуальная версия
CONTAINERD_VERSION="latest"

# Functions
check_os() { ... }
disable_swap() { ... }
configure_sysctl() { ... }
install_containerd() { ... }
install_kubernetes() { ... }
configure_services() { ... }
cleanup_for_template() { ... }

# Main execution
main() {
    log "Starting Kubernetes node preparation"
    check_os
    disable_swap
    configure_sysctl
    install_containerd
    install_kubernetes
    configure_services
    cleanup_for_template
    log "Preparation completed successfully"
}

main "$@"
```

**Требования:**
- Логирование всех действий
- Проверка ошибок на каждом шаге
- Возможность запуска в non-interactive режиме
- Совместимость с Ubuntu 24.04

---

### 3.2. Вспомогательные скрипты
Создай файл `scripts/validate-vm-template.sh`:

**Цель:** Проверка готовности Template после создания.

**Проверки:**
- Версии компонентов (containerd, kubeadm, kubelet, kubectl)
- Настройки sysctl
- Состояние swap (должен быть off)
- Cloud-init configuration
- Systemd services status

Создай файл `scripts/cleanup-vm-for-template.sh`:

**Цель:** Финальная очистка перед созданием Template.

**Действия:**
- Очистка логов (`/var/log/*`)
- Очистка bash history
- Сброс machine-id
- Удаление SSH host keys
- Очистка cloud-init logs
- Очистка package cache

---

## ЭТАП 4: Cloud-init конфигурации

**Твоя задача:** Создать готовые cloud-init конфигурации для разных типов нод.

### 4.1. Базовая cloud-init конфигурация
Создай файл `vm-templates/cloud-init-base.yaml`:

**Функции:**
- Настройка hostname (из metadata)
- Настройка статических IP (из metadata)
- Создание пользователей и SSH ключей
- Базовые sysctl settings
- Настройка DNS

**Пример структуры:**
```yaml
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.${domain}

users:
  - name: k8s-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}

write_files:
  - path: /etc/netplan/01-static-ip.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [${ip_address}/${subnet_mask}]
            gateway4: ${gateway}
            nameservers:
              addresses: [${dns_servers}]

runcmd:
  - netplan apply
  - systemctl enable containerd kubelet
  - # Additional commands
```

### 4.2. Специфичные конфигурации
Создай файлы:
- `vm-templates/cloud-init-control-plane.yaml` — для Control Plane нод
- `vm-templates/cloud-init-worker.yaml` — для Worker нод

**Различия:**
- Control Plane: дополнительные порты в firewall, etcd настройки
- Workers: настройки для workloads, возможно GPU drivers (в будущем)

### 4.3. Примеры использования
Создай файл `vm-templates/examples/README.md`:

**Примеры создания VM из Template:**
- Через vSphere UI с cloud-init customization
- Через Terraform (если используется)
- Переменные для IP-адресов, hostnames

---

## ЭТАП 5: Валидация и документация

**Твоя задача:** Создать проверочные процедуры и финальную документацию.

### 5.1. Чек-лист валидации Template
Создай файл `research/vm-preparation/06-validation-checklist.md`:

**Проверки Template:**
- [ ] Ubuntu 24.04 LTS установлена
- [ ] Kubernetes компоненты установлены (правильные версии)
- [ ] containerd настроен и работает
- [ ] sysctl настройки применены
- [ ] swap отключен
- [ ] cloud-init настроен
- [ ] Template создан в vSphere

**Проверки клонированной VM:**
- [ ] VM клонируется без ошибок
- [ ] Cloud-init отрабатывает корректно
- [ ] Статический IP настраивается
- [ ] SSH доступ работает
- [ ] Kubernetes компоненты готовы к использованию

### 5.2. Тестирование первого клона
Создай файл `research/vm-preparation/07-first-clone-test.md`:

**Процедура тестирования:**
1. Клонирование VM из Template
2. Настройка cloud-init с тестовыми параметрами
3. Запуск и проверка cloud-init logs
4. Валидация всех компонентов
5. Тест готовности к kubeadm init

**Тестовые параметры:**
- IP: `10.246.10.250` (тестовый)
- Hostname: `k8s-test-node`
- SSH ключ оператора

### 5.3. Финальная документация
Создай файл `research/vm-preparation/08-final-documentation.md`:

**Сводка результатов:**
- Созданные артефакты (Template, скрипты, cloud-init)
- Версии компонентов
- Особенности и ограничения
- Рекомендации для Production

**Готовые параметры для следующего этапа:**
- Имя Template в vSphere
- Рекомендуемые настройки клонирования
- Cloud-init параметры для разных типов нод

---

## Дополнительные требования

### Стиль выполнения:
✅ **Делай:**
- Пиши готовые к использованию скрипты
- Тестируй все команды на совместимость с Ubuntu 24.04
- Предусматривай обработку ошибок
- Документируй все нестандартные решения

❌ **Не делай:**
- Не используй deprecated пакеты или методы
- Не игнорируй версионную совместимость
- Не создавай слишком сложные конфигурации (это PoC)

### Особенности работы с оператором:
- Оператор опытный в vSphere, но может быть новичком в K8s
- Все действия будут выполняться на реальной инфраструктуре
- Предпочтение автоматизации над ручными действиями

---

## Артефакты на выходе

### Обязательные документы:
- [ ] `01-version-analysis.md` — анализ версий
- [ ] `02-template-strategy.md` — стратегия Template
- [ ] `03-base-vm-creation.md` — создание базовой VM
- [ ] `04-k8s-installation.md` — установка K8s компонентов
- [ ] `05-template-finalization.md` — финализация Template
- [ ] `06-validation-checklist.md` — проверочные процедуры
- [ ] `07-first-clone-test.md` — тестирование клонирования
- [ ] `08-final-documentation.md` — финальная сводка

### Обязательные скрипты:
- [ ] `scripts/prepare-vm.sh` — основной скрипт подготовки
- [ ] `scripts/validate-vm-template.sh` — валидация Template
- [ ] `scripts/cleanup-vm-for-template.sh` — очистка перед Template

### Обязательные конфигурации:
- [ ] `vm-templates/cloud-init-base.yaml` — базовая cloud-init
- [ ] `vm-templates/cloud-init-control-plane.yaml` — для CP нод
- [ ] `vm-templates/cloud-init-worker.yaml` — для Worker нод
- [ ] `vm-templates/examples/README.md` — примеры использования

### Списки и справочники:
- [ ] `vm-templates/packages-list.txt` — список установленных пакетов
- [ ] `vm-templates/sysctl-settings.conf` — настройки sysctl
- [ ] `vm-templates/systemd-services.list` — список systemd services

---

## Критерии успеха

Задание считается выполненным, когда:

✅ **Template готов:**
- VM Template создан в vSphere
- Все K8s компоненты предустановлены и настроены
- Cloud-init готов к автоматизации клонирования

✅ **Скрипты работают:**
- prepare-vm.sh успешно подготавливает VM
- validate-vm-template.sh подтверждает готовность
- Cloud-init конфигурации корректно применяются

✅ **Документация полная:**
- Все инструкции пошаговые и воспроизводимые
- Version matrix актуальна
- Тестирование проведено и задокументировано

✅ **Готовность к следующему этапу:**
- Template готов для клонирования K8s нод
- Параметры IP/hostname настраиваются через cloud-init
- Первый тестовый клон успешно создан

---

## Координация с Team Lead

**После завершения задания:**
1. Все артефакты созданы в соответствующих папках
2. Оператор прошёл тестирование первого клона
3. Team Lead обновляет PROJECT-PLAN.md (Этап 0.2 → COMPLETED)
4. Переход к Этапу 1.1 (Cluster Bootstrap)

**Если возникают вопросы:**
Создай файл `research/vm-preparation/QUESTIONS-FOR-TEAM-LEAD.md` с вопросами.

---

**Удачи, AI-агент! Помни: твоя цель — создать готовый к использованию VM Template с максимальной автоматизацией. Все скрипты должны работать "из коробки".**

🚀 **Начинай с Этапа 1 (Анализ требований)!**
