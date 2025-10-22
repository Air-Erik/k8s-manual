# NAT Configuration for Kubernetes Cluster

> **Статус:** 🟢 COMPLETED (Настройка завершена)
> **Дата обновления:** 2025-01-17
> **Оператор:** Ayrapetov_es

---

## Обзор

Этот документ фиксирует **NAT конфигурацию** для изолированного Kubernetes кластера на T1-k8s-zeon-dev.

**Принцип:** 3 NAT правила обеспечивают корректную маршрутизацию трафика от k8s нод (10.246.10.0/24) к различным назначениям.

---

## NAT Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    T1-k8s-zeon-dev                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                NAT Rules (Priority)                 │   │
│  │                                                     │   │
│  │  1. no_snat_to_internal                             │   │
│  │     Source: 10.246.10.0/24 → Internal Networks    │   │
│  │     Action: No-SNAT (preserve source IP)          │   │
│  │                                                     │   │
│  │  2. no_snat_to_vips                                 │   │
│  │     Source: 10.246.10.0/24 → 172.16.50.192/27      │   │
│  │     Action: No-SNAT (preserve source IP)          │   │
│  │                                                     │   │
│  │  3. snat_to_internet (catch-all)                    │   │
│  │     Source: 10.246.10.0/24 → Any                   │   │
│  │     Action: SNAT to 172.16.50.170                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## NAT Rules Details

### 1. No-SNAT к внутренним сетям

| Параметр | Значение |
|----------|---------|
| **Rule Name** | `no_snat_to_internal` |
| **Type** | `No-SNAT` |
| **Priority** | `1000` (высший) |
| **Source** | `10.246.10.0/24` |
| **Destination** | `Any` |
| **Translated IP** | `N/A` |
| **Applied To** | `T1-k8s-zeon-dev` |
| **Status** | `Active` |

**Назначение:**
- Сохраняет исходный IP при обращении к внутренним сетям
- Позволяет k8s нодам обращаться к реестрам, CI/CD без NAT
- Обеспечивает корректную аутентификацию по IP

**Примеры использования:**
- Доступ к внутренним Docker registry
- Обращение к CI/CD системам
- Внутренние API вызовы

---

### 2. No-SNAT к VIP пулу

| Параметр | Значение |
|----------|---------|
| **Rule Name** | `no_snat_to_vips` |
| **Type** | `No-SNAT` |
| **Priority** | `1001` |
| **Source** | `10.246.10.0/24` |
| **Destination** | `172.16.50.192/27` |
| **Translated IP** | `N/A` |
| **Applied To** | `T1-k8s-zeon-dev` |
| **Status** | `Active` |

**Назначение:**
- Сохраняет исходный IP при обращении к Ingress VIP
- Предотвращает hairpin проблемы
- Обеспечивает корректную работу health checks

**VIP Pool Details:**
- **Range:** `172.16.50.192/27` (32 IP)
- **Available IPs:** `172.16.50.193-222`
- **Usage:** MetalLB LoadBalancer services, Ingress VIP

**Примеры использования:**
- Health checks от k8s нод к Ingress VIP
- Внутренние вызовы к LoadBalancer services
- Мониторинг и метрики

---

### 3. SNAT к интернету (catch-all)

| Параметр | Значение |
|----------|---------|
| **Rule Name** | `snat_to_internet` |
| **Type** | `SNAT` |
| **Priority** | `1002` (низший) |
| **Source** | `10.246.10.0/24` |
| **Destination** | `Any` |
| **Translated IP** | `172.16.50.170` |
| **Applied To** | `T1-k8s-zeon-dev` |
| **Status** | `Active` |

**Назначение:**
- Маскирует весь egress-трафик в один внешний IP
- Обеспечивает доступ в интернет без изменения upstream маршрутизации
- Упрощает firewall правила на периметре

**SNAT IP Details:**
- **IP:** `172.16.50.170`
- **Type:** Static allocation from 172.16.50.0/24 pool
- **Usage:** Egress traffic from k8s cluster

**Примеры использования:**
- Скачивание Docker images
- Обновления пакетов
- API вызовы к внешним сервисам

---

## Traffic Flow Examples

### 1. Egress в интернет
```
k8s-node (10.246.10.10) → 8.8.8.8
├─ Matches: snat_to_internet
├─ Source IP: 10.246.10.10 → 172.16.50.170
└─ Result: Internet access with SNAT
```

### 2. Доступ к Ingress VIP
```
k8s-node (10.246.10.10) → 172.16.50.200 (Ingress VIP)
├─ Matches: no_snat_to_vips
├─ Source IP: 10.246.10.10 (preserved)
└─ Result: No hairpin problems
```

### 3. Доступ к внутренним сетям
```
k8s-node (10.246.10.10) → 172.16.100.50 (Internal API)
├─ Matches: no_snat_to_internal
├─ Source IP: 10.246.10.10 (preserved)
└─ Result: Internal access without NAT
```

---

## NAT Rule Priority

**Критически важно:** Порядок NAT правил определяет, какое правило применится к трафику.

```
Priority 1000: no_snat_to_internal    (высший приоритет)
Priority 1001: no_snat_to_vips
Priority 1002: snat_to_internet       (низший приоритет)
```

**Логика обработки:**
1. **Проверяется** `no_snat_to_internal` — если совпадает, применяется No-SNAT
2. **Проверяется** `no_snat_to_vips` — если совпадает, применяется No-SNAT
3. **Проверяется** `snat_to_internet` — catch-all правило, применяется SNAT

---

## Monitoring and Troubleshooting

### NAT Statistics
```bash
# Проверка статистики в NSX UI:
# Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Rules
# Смотреть колонку "Hits" для каждого правила

# Ожидаемые значения:
# - no_snat_to_internal: 0-50 hits (внутренние вызовы)
# - no_snat_to_vips: 0-100 hits (health checks)
# - snat_to_internet: 100+ hits (интернет трафик)
```

### NAT Debug Commands
```bash
# С k8s ноды проверить SNAT:
curl ifconfig.me
# Ожидаемый результат: 172.16.50.170

# Проверить No-SNAT к VIP:
curl -I http://172.16.50.200
# Должен работать без ошибок

# Проверить No-SNAT к внутренним:
curl -I http://172.16.100.50
# Должен работать с исходным IP
```

### Traceflow Analysis
```bash
# NSX UI → Plan & Troubleshoot → Traceflow
# Source: 10.246.10.10
# Destination: 8.8.8.8
# Ожидаемый путь: VM → T1 → NAT → T0 → Internet
# Ожидаемый SNAT: 10.246.10.10 → 172.16.50.170
```

---

## Security Considerations

### NAT Security Benefits
- **Изоляция egress:** Весь исходящий трафик маскируется в один IP
- **Упрощение firewall:** На периметре нужно разрешить только 172.16.50.170
- **Аудит трафика:** Все egress-действия логируются с одним исходным IP

### NAT Security Risks
- **Потеря исходного IP:** Для интернет-трафика теряется информация об исходном узле
- **Hairpin проблемы:** Неправильная настройка может вызвать проблемы с возвратным трафиком

### Best Practices
- **Порядок правил:** No-SNAT всегда выше SNAT
- **Мониторинг:** Регулярно проверять статистику NAT правил
- **Тестирование:** Проверять все сценарии трафика после изменений

---

## Backup and Recovery

### NAT Rules Export
```bash
# Экспорт NAT правил в NSX UI:
# Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Export
# Сохранить в: nsx-configs/t1-k8s-zeon-dev-nat-rules.json
```

### NAT Rules Import
```bash
# Восстановление NAT правил:
# Networking → Tier-1 Gateways → T1-k8s-zeon-dev → NAT → Import
# Загрузить из: nsx-configs/t1-k8s-zeon-dev-nat-rules.json
```

---

## Использование в Kubernetes Deployment

**NAT конфигурация используется в следующих этапах:**

1. **Этап 1.1 (Cluster Bootstrap):**
   - SNAT 172.16.50.170 для скачивания образов
   - No-SNAT для доступа к vCenter

2. **Этап 1.4 (MetalLB Setup):**
   - No-SNAT к VIP пулу 172.16.50.192/27
   - SNAT для egress от LoadBalancer services

3. **Этап 1.5 (Ingress Setup):**
   - No-SNAT к Ingress VIP для health checks
   - SNAT для egress от Ingress controller

---

## Изменения и апдейты

| Дата | Изменение | Автор |
|------|-----------|-------|
| `2025-01-17` | Первоначальная настройка NAT правил | `Ayrapetov_es` |
| | | |

---

## Контакты

**NSX Admin:** `Ayrapetov_es` (для вопросов по NAT)
**Kubernetes Admin:** `Ayrapetov_es`

---

**Этот документ — источник правды для NAT конфигурации k8s кластера.**
**Обновляй его при любых изменениях в NAT правилах!**
