# VM Preparation and Template Creation

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** NSX-T сегмент создан (01-nsx-network-setup.md)

## Цель
Подготовить VM-шаблон Ubuntu 24.04 LTS с необходимыми пакетами и настройками для Kubernetes-нод.

## Артефакты на выходе
- VM-шаблон в vSphere для Control Plane
- VM-шаблон в vSphere для Workers (опционально, может быть тот же)
- Cloud-init конфигурация в `vm-templates/cloud-init.yaml`
- Скрипт подготовки ноды `scripts/prepare-vm.sh`
- Список пакетов `vm-templates/packages-list.txt`

## Задачи
- [ ] Создать базовую VM Ubuntu 24.04 LTS
- [ ] Установить containerd, kubeadm, kubelet, kubectl
- [ ] Настроить sysctl (ip_forward, bridge-nf-call-iptables)
- [ ] Отключить swap
- [ ] Настроить cloud-init для автоматизации
- [ ] Создать VM Template в vSphere
- [ ] Задокументировать процесс

## Требования к VM
- Ubuntu 24.04 LTS (minimal install)
- Kubernetes 1.34.x
- containerd (CRI)
- Network: подключение к NSX-T segment
- Статические IP или DHCP с резервированием

## Инструкции

*TODO: Будут добавлены AI-исполнителем с командами и скриптами.*
