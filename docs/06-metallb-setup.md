# MetalLB Setup (L2 Mode)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** Кластер работает, CNI установлен (04-cni-setup.md)

## Цель
Установить MetalLB LoadBalancer в L2 режиме и настроить IP Pool для Service LoadBalancer.

## Артефакты на выходе
- MetalLB манифесты в `manifests/metallb/`
- IPAddressPool и L2Advertisement манифесты
- Тестовый Service LoadBalancer

## Задачи
- [ ] Зарезервировать IP-диапазон для MetalLB (из NSX-T IP-плана)
- [ ] Проверить IP свободны (ping sweep)
- [ ] Добавить IP в SpoofGuard whitelist (если не сделано в 01)
- [ ] Установить MetalLB (через манифесты или Helm)
- [ ] Создать IPAddressPool
- [ ] Создать L2Advertisement
- [ ] Тестировать с примером Service LoadBalancer
- [ ] Проверить доступность внешнего IP

## Инструкции

*TODO: Будут добавлены AI-исполнителем.*

## Проверка
```bash
kubectl get pods -n metallb-system
kubectl apply -f manifests/examples/test-lb-service.yaml
kubectl get svc -A | grep LoadBalancer
curl http://<EXTERNAL-IP>
```
