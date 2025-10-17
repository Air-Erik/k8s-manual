# Storage Setup (vSphere CSI Driver)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** Кластер работает, CNI установлен (04-cni-setup.md)

## Цель
Установить vSphere CSI Driver и настроить StorageClass для динамического provisioning PV.

## Артефакты на выходе
- vSphere CSI манифесты в `manifests/vsphere-csi/`
- Secret с vCenter credentials
- StorageClass (default)
- Тестовый PVC для проверки

## Задачи
- [ ] Определить датастор и SPBM политику
- [ ] Создать Secret с vCenter credentials
- [ ] Установить vSphere CSI Driver (через манифесты или Helm)
- [ ] Создать StorageClass (пометить как default)
- [ ] Тестировать создание PVC и pod с монтированием
- [ ] Проверить производительность (опционально, fio benchmark)

## Инструкции

*TODO: Будут добавлены AI-исполнителем.*

## Проверка
```bash
kubectl get sc
kubectl get pvc
kubectl apply -f manifests/examples/storage-test.yaml
kubectl exec -it storage-test-pod -- df -h
```
