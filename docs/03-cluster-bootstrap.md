# Cluster Bootstrap (kubeadm + kube-vip)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** VM-шаблон готов (02-vm-preparation.md), NSX-T настроен (01)

## Цель
Инициализировать Kubernetes Control Plane с HA через kube-vip и присоединить worker-ноды.

## Артефакты на выходе
- `kubeadm-config.yaml` в `manifests/kube-vip/`
- kube-vip манифест Static Pod в `manifests/kube-vip/`
- Скрипт `scripts/bootstrap-control-plane.sh`
- Скрипт `scripts/join-worker.sh`
- kubeconfig для доступа к кластеру

## Задачи
- [ ] Создать 3 VM для Control Plane из шаблона
- [ ] Создать 2+ VM для Workers
- [ ] Настроить kube-vip Static Pod на первой CP ноде
- [ ] Выполнить `kubeadm init` на первой CP ноде
- [ ] Скопировать kube-vip на остальные CP ноды
- [ ] Join остальные CP ноды (`kubeadm join --control-plane`)
- [ ] Join Worker ноды (`kubeadm join`)
- [ ] Проверить API VIP доступен
- [ ] Проверить все ноды в статусе **Ready** (будет после CNI)

## Инструкции

*TODO: Будут добавлены AI-исполнителем с пошаговыми командами.*

## Проверка
```bash
kubectl get nodes
kubectl get pods -A
curl -k https://<API-VIP>:6443/version
```
