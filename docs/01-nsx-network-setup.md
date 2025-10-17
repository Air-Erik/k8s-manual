# NSX-T Network Setup

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** Доступ к NSX-T Manager

## Цель
Настроить NSX-T сегмент для Kubernetes-нод, IP-адресацию, DFW-правила и SpoofGuard whitelist.

## Артефакты на выходе
- Созданный NSX-T Segment для k8s-нод
- Зафиксированный IP-план (VM subnet, API VIP, MetalLB pool)
- DFW-правила для группы `k8s-nodes`
- SpoofGuard whitelist для VIP и MetalLB
- MTU согласованность проверена

## Задачи
- [ ] Создать NSX-T Segment
- [ ] Определить подсеть, gateway, DNS
- [ ] Зарезервировать API VIP и MetalLB IP pool
- [ ] Создать группу `k8s-nodes` в NSX
- [ ] Настроить DFW rules (allow inter-node, NodePort, egress)
- [ ] Настроить SpoofGuard whitelist
- [ ] Проверить MTU end-to-end
- [ ] Документировать финальные параметры в `nsx-configs/segments.md`

## Инструкции

*TODO: Будут добавлены AI-исполнителем с пошаговыми скриншотами/командами.*
