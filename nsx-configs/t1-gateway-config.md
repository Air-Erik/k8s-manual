# T1 Gateway Configuration for Kubernetes Cluster

> **Статус:** 🟢 COMPLETED (Настройка завершена)
> **Дата обновления:** 2025-01-17
> **Оператор:** Ayrapetov_es

---

## Обзор

Этот документ фиксирует **конфигурацию T1 Gateway** для изолированного Kubernetes кластера.

**T1 Gateway:** `T1-k8s-zeon-dev` — отдельный Tier-1 Gateway для полной изоляции k8s кластера от существующих Tanzu кластеров.

---

## T1 Gateway Information

| Параметр | Значение | Примечания |
|----------|---------|-----------|
| **T1 Gateway Name** | `T1-k8s-zeon-dev` | Имя T1 Gateway в NSX-T |
| **Tier-0 Gateway** | `TO-GW` | Подключен к существующему T0 |
| **Edge Cluster** | `EC-1` | Edge Cluster для T1 |
| **HA Mode** | `Active-Standby` | Высокая доступность |
| **Route Advertisement** | `Connected Segments + NAT IPs` | Анонс маршрутов в T0 |

---

## Route Advertisement Configuration

**Настройки Route Advertisement на T1-k8s-zeon-dev:**

| Настройка | Значение | Назначение |
|-----------|---------|------------|
| **All Connected Segments & Service Ports** | `Enabled` | Анонс сегмента 10.246.10.0/24 в T0 |
| **All NAT IPs** | `Enabled` | Анонс SNAT IP 172.16.50.170 в T0 |
| **All LB VIP Routes** | `Disabled` | Не используется NSX Load Balancer |
| **All Static Routes** | `Disabled` | Статические маршруты не настроены |

---

## Connected Segments

| Segment Name | Subnet | Gateway IP | Transport Zone |
|--------------|--------|------------|----------------|
| `k8s-zeon-dev-segment` | `10.246.10.0/24` | `10.246.10.1/24` | `nsx-overlay-transportzone` |

---

## NAT Rules Configuration

**NAT правила на T1-k8s-zeon-dev (в порядке приоритета):**

### 1. No-SNAT к внутренним сетям
| Параметр | Значение |
|----------|---------|
| **Rule Name** | `no_snat_to_internal` |
| **Type** | `No-SNAT` |
| **Source** | `10.246.10.0/24` |
| **Destination** | `Any` |
| **Translated IP** | `N/A` |
| **Назначение** | Доступ к внутренним сетям (реестры, CI) без NAT |

### 2. No-SNAT к VIP пулу
| Параметр | Значение |
|----------|---------|
| **Rule Name** | `no_snat_to_vips` |
| **Type** | `No-SNAT` |
| **Source** | `10.246.10.0/24` |
| **Destination** | `172.16.50.192/27` |
| **Translated IP** | `N/A` |
| **Назначение** | Доступ к Ingress VIP без hairpin проблем |

### 3. SNAT к интернету
| Параметр | Значение |
|----------|---------|
| **Rule Name** | `snat_to_internet` |
| **Type** | `SNAT` |
| **Source** | `10.246.10.0/24` |
| **Destination** | `Any` |
| **Translated IP** | `172.16.50.170` |
| **Назначение** | Egress в интернет через единый внешний IP |

---

## Gateway Firewall Rules

**Gateway Firewall на T1-k8s-zeon-dev:**

| Rule | Source | Destination | Service | Action | Status |
|------|--------|-------------|---------|--------|--------|
| **Default** | `Any` | `Any` | `Any` | `Allow` | ✅ Active |

**Примечание:** Gateway Firewall настроен в режиме "Allow All" для упрощения начальной настройки.

---

## Routing Table

**Маршруты на T1-k8s-zeon-dev:**

| Destination | Next Hop | Type | Status |
|-------------|----------|------|--------|
| `10.246.10.0/24` | `Local` | `Connected` | ✅ Active |
| `0.0.0.0/0` | `TO-GW` | `Default Route` | ✅ Active |

---

## Connectivity Tests

**Проверка связности T1 Gateway:**

| Test | Command | Result | Notes |
|------|---------|--------|-------|
| **T1 → T0** | `ping 172.16.50.1` | ✅ Pass | Связность с T0 uplink |
| **T1 → Internet** | `ping 8.8.8.8` | ✅ Pass | Через SNAT 172.16.50.170 |
| **T1 → VIP Pool** | `ping 172.16.50.200` | ✅ Pass | No-SNAT работает |
| **T1 → Internal** | `ping 172.16.100.1` | ✅ Pass | No-SNAT к внутренним сетям |

---

## Monitoring and Troubleshooting

### NAT Statistics
```bash
# Проверка статистики NAT правил в NSX UI:
# Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Rules
# Смотреть колонку "Hits" для каждого правила
```

### Route Advertisement Status
```bash
# Проверка анонса маршрутов в NSX UI:
# Networking → Tier-0 Gateways → TO-GW → Routing → Routes
# Должны быть видны:
# - 10.246.10.0/24 (Connected Segment)
# - 172.16.50.170/32 (NAT IP)
```

### Traceflow
```bash
# Диагностика трафика в NSX UI:
# Plan & Troubleshoot → Traceflow
# Source: 10.246.10.10 (VM IP)
# Destination: 8.8.8.8
# Ожидаемый путь: VM → T1 → T0 → Internet
```

---

## Security Considerations

### Изоляция
- **Отдельный T1** обеспечивает полную изоляцию от Tanzu кластеров
- **Собственная подсеть** 10.246.10.0/24 не пересекается с существующими сетями
- **Собственный SNAT IP** 172.16.50.170 изолирует egress-трафик

### NAT Security
- **No-SNAT правила** позволяют сохранять исходные IP для внутренних вызовов
- **SNAT правило** маскирует весь egress-трафик в один внешний IP
- **Порядок NAT правил** критичен: No-SNAT должны быть выше SNAT

---

## Backup and Recovery

### Конфигурация T1
```bash
# Экспорт конфигурации T1 Gateway:
# NSX UI → Networking → Tier-1 Gateways → T1-k8s-zeon-dev → Export
# Сохранить в: nsx-configs/t1-k8s-zeon-dev-config.json
```

### NAT Rules Backup
```bash
# Экспорт NAT правил:
# NSX UI → Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Export
# Сохранить в: nsx-configs/t1-k8s-zeon-dev-nat-rules.json
```

---

## Использование в Kubernetes Deployment

**Этот T1 Gateway используется в следующих этапах:**

1. **Этап 0.2 (VM Preparation):**
   - Gateway IP 10.246.10.1 для настройки VM
   - DNS 172.17.10.3 + 8.8.8.8 для cloud-init

2. **Этап 1.1 (Cluster Bootstrap):**
   - Подсеть 10.246.10.0/24 для kubeadm init
   - Gateway 10.246.10.1 для маршрутизации

3. **Этап 1.4 (MetalLB Setup):**
   - No-SNAT к VIP пулу 172.16.50.192/27
   - SNAT 172.16.50.170 для egress

4. **Этап 1.3 (Storage Setup):**
   - No-SNAT к внутренним сетям для vCenter access

---

## Изменения и апдейты

| Дата | Изменение | Автор |
|------|-----------|-------|
| `2025-01-17` | Первоначальная настройка T1-k8s-zeon-dev | `Ayrapetov_es` |
| | | |

---

## Контакты

**NSX Admin:** `Ayrapetov_es` (для вопросов по NSX-T)
**Kubernetes Admin:** `Ayrapetov_es`

---

**Этот документ — источник правды для конфигурации T1 Gateway k8s кластера.**
**Обновляй его при любых изменениях в T1-k8s-zeon-dev!**
