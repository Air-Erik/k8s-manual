# Observability Setup (metrics-server, Prometheus, Grafana)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** Кластер базово работает (04-07 выполнены)

## Цель
Настроить базовый мониторинг и observability для кластера.

## Артефакты на выходе
- metrics-server манифесты в `manifests/observability/`
- (Опционально) Prometheus + Grafana Helm values
- Инструкции по доступу к Grafana UI

## Задачи
- [ ] Установить metrics-server
- [ ] Проверить `kubectl top nodes` и `kubectl top pods`
- [ ] (Опционально для Prod) Установить Prometheus Operator
- [ ] (Опционально) Установить Grafana
- [ ] (Опционально) Настроить ServiceMonitors для Cilium, MetalLB, etc.
- [ ] (Опционально) Импортировать дашборды для Kubernetes

## Инструкции

*TODO: Будут добавлены AI-исполнителем.*

## Проверка
```bash
kubectl top nodes
kubectl top pods -A
# Если Grafana:
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Открыть http://localhost:3000
```
