# Ingress Setup (NGINX Ingress Controller)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** MetalLB работает (06-metallb-setup.md)

## Цель
Установить NGINX Ingress Controller и настроить базовый Ingress для HTTP/HTTPS маршрутизации.

## Артефакты на выходе
- NGINX Ingress манифесты или Helm values в `manifests/ingress-nginx/`
- Тестовый Ingress с примером приложения
- TLS сертификат (self-signed или настоящий)

## Задачи
- [ ] Установить NGINX Ingress Controller (через Helm)
- [ ] Убедиться что Ingress Service получил LoadBalancer IP от MetalLB
- [ ] Создать тестовый Deployment + Service + Ingress
- [ ] Настроить DNS (вручную или через /etc/hosts)
- [ ] Проверить HTTP доступ
- [ ] (Опционально) Настроить HTTPS с cert-manager или self-signed

## Инструкции

*TODO: Будут добавлены AI-исполнителем.*

## Проверка
```bash
kubectl get svc -n ingress-nginx
kubectl get ingress -A
curl http://<ingress-hostname>
curl -k https://<ingress-hostname>
```
