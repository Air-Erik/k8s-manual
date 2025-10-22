# NSX-T Configuration for Kubernetes Cluster

> **Статус:** 🟢 COMPLETED (Настройка завершена)
> **Дата обновления:** 2025-01-17
> **Оператор:** Ayrapetov_es

---

## Обзор

Эта папка содержит **финальные конфигурации NSX-T** для изолированного Kubernetes кластера.

**Архитектура:** Отдельный T1 Gateway + изолированный сегмент для полной изоляции от существующих Tanzu кластеров.

---

## Документы

### 📋 Основные конфигурации

| Документ | Описание | Статус |
|----------|----------|--------|
| [`segments.md`](./segments.md) | **Основной документ** — параметры сегмента, IP-план, DNS, валидация | ✅ Complete |
| [`t1-gateway-config.md`](./t1-gateway-config.md) | Конфигурация T1 Gateway, Route Advertisement, Gateway Firewall | ✅ Complete |
| [`nat-configuration.md`](./nat-configuration.md) | NAT правила, трафик-флоу, мониторинг | ✅ Complete |

---

## Быстрый справочник

### 🎯 Ключевые параметры

| Параметр | Значение | Назначение |
|----------|---------|------------|
| **T1 Gateway** | `T1-k8s-zeon-dev` | Маршрутизация для k8s кластера |
| **Сегмент** | `k8s-zeon-dev-segment` | Сеть для k8s нод |
| **VM Subnet** | `10.246.10.0/24` | IP-диапазон для нод |
| **Gateway IP** | `10.246.10.1/24` | Шлюз для нод |
| **SNAT IP** | `172.16.50.170` | Egress-IP для интернета |
| **VIP Pool** | `172.16.50.192/27` | Пул для LoadBalancer/Ingress |
| **DNS** | `172.17.10.3` + `8.8.8.8` | DNS серверы |

### 🔧 NAT правила (T1-k8s-zeon-dev)

| Правило | Тип | Источник | Назначение | Действие |
|---------|-----|----------|------------|----------|
| `no_snat_to_internal` | No-SNAT | `10.246.10.0/24` | `Any` | Сохранить исходный IP |
| `no_snat_to_vips` | No-SNAT | `10.246.10.0/24` | `172.16.50.192/27` | Сохранить исходный IP |
| `snat_to_internet` | SNAT | `10.246.10.0/24` | `Any` | `172.16.50.170` |

### 📊 IP-план (10.246.10.0/24)

| IP Range | Назначение | Статус |
|----------|------------|--------|
| `10.246.10.1` | Gateway (T1) | ✅ Reserved |
| `10.246.10.10-12` | Control Plane (3 ноды) | ✅ Reserved |
| `10.246.10.20-30` | Worker Nodes (10 нод) | ✅ Reserved |
| `10.246.10.100` | API VIP (kube-vip) | ✅ Reserved |
| `10.246.10.200-220` | MetalLB Pool (20 IP) | ✅ Reserved |
| `10.246.10.50-99` | Future Use | ✅ Available |

---

## Использование в Kubernetes Deployment

### Этап 0.2: VM Preparation
- **Subnet:** `10.246.10.0/24` для настройки статических IP
- **Gateway:** `10.246.10.1` для маршрутизации
- **DNS:** `172.17.10.3, 8.8.8.8` для cloud-init

### Этап 1.1: Cluster Bootstrap
- **API VIP:** `10.246.10.100` для kube-vip
- **Control Plane IPs:** `10.246.10.10-12` для kubeadm init

### Этап 1.4: MetalLB Setup
- **IP Pool:** `10.246.10.200-220` для LoadBalancer services
- **No-SNAT:** к VIP пулу `172.16.50.192/27`

### Этап 1.5: Ingress Setup
- **Ingress VIP:** из пула `172.16.50.192/27`
- **No-SNAT:** для health checks от нод

---

## Мониторинг и диагностика

### Проверка связности
```bash
# С k8s ноды:
ping 8.8.8.8                    # Интернет через SNAT
curl ifconfig.me                # Должен вернуть 172.16.50.170
ping 172.16.50.200              # VIP без hairpin проблем
```

### NSX UI проверки
```bash
# NAT статистика:
# Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Rules

# Route Advertisement:
# Networking → Tier-0 Gateways → TO-GW → Routing → Routes

# Traceflow:
# Plan & Troubleshoot → Traceflow
```

---

## Безопасность

### Изоляция
- **Отдельный T1** — полная изоляция от Tanzu кластеров
- **Собственная подсеть** — не пересекается с существующими сетями
- **Собственный SNAT** — изолированный egress-трафик

### NAT Security
- **No-SNAT правила** — сохраняют исходные IP для внутренних вызовов
- **SNAT правило** — маскирует egress-трафик в один внешний IP
- **Порядок правил** — No-SNAT выше SNAT

---

## Backup и Recovery

### Экспорт конфигураций
```bash
# T1 Gateway:
# NSX UI → Networking → Tier-1 Gateways → T1-k8s-zeon-dev → Export

# NAT Rules:
# NSX UI → Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Export

# Segment:
# NSX UI → Networking → Segments → k8s-zeon-dev-segment → Export
```

### Восстановление
```bash
# Импорт конфигураций в NSX UI:
# Networking → Tier-1 Gateways → Import
# Networking → Segments → Import
```

---

## Контакты

**NSX Admin:** `Ayrapetov_es`
**Kubernetes Admin:** `Ayrapetov_es`

---

## Изменения

| Дата | Изменение | Автор |
|------|-----------|-------|
| `2025-01-17` | Первоначальная настройка NSX-T | `Ayrapetov_es` |
| | | |

---

**Эта папка — источник правды для сетевых параметров K8s кластера.**
**Обновляй документы при любых изменениях в NSX-T!**
