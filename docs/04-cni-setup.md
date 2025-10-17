# CNI Setup (Cilium)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** Кластер bootstrap (03-cluster-bootstrap.md)

## Цель
Установить и настроить Cilium CNI с правильным MTU, kube-proxy replacement и Hubble observability.

## Артефакты на выходе
- Cilium Helm values в `manifests/cilium/values.yaml`
- Инструкция по установке через Helm или манифесты
- Проверочные тесты connectivity

## Задачи
- [ ] Определить правильный MTU (согласовать с NSX overlay)
- [ ] Создать Cilium values.yaml с:
  - MTU
  - kube-proxy replacement (если требуется)
  - Hubble UI (опционально)
  - IPAM mode (kubernetes)
- [ ] Установить Cilium через Helm
- [ ] Проверить все поды Cilium запустились
- [ ] Запустить `cilium connectivity test`
- [ ] Проверить все ноды теперь **Ready**

## Инструкции

*TODO: Будут добавлены AI-исполнителем.*

## Проверка
```bash
kubectl get nodes  # Все Ready
cilium status
cilium connectivity test
kubectl -n kube-system get pods -l k8s-app=cilium
```
