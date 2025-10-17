# SpoofGuard Whitelist для Kubernetes Cluster

> **Статус:** 🟡 Ожидает заполнения после настройки NSX-T
> **Дата обновления:** ___________
> **Оператор:** ___________

---

## Обзор

**SpoofGuard** в NSX-T защищает от IP/MAC spoofing, но может блокировать легитимные use-cases, такие как:
- **kube-vip** — gratuitous ARP для API VIP
- **MetalLB (L2 mode)** — gratuitous ARP для LoadBalancer IP

Этот документ фиксирует IP-адреса, которые должны быть **разрешены** (whitelisted) в SpoofGuard.

---

## SpoofGuard Configuration

**Режим:** `[ ] Enabled with whitelist` / `[ ] Disabled for k8s-nodes ports`

**Если Enabled:**
- **SpoofGuard Profile Name:** `____________`
- **Applied to:** `[ ] Segment level` / `[ ] Port level (per VM)`

**Если Disabled:**
- ⚠️ **Security Note:** SpoofGuard отключен для упрощения PoC. Для Production рекомендуется **включить с whitelist**.

---

## Allowed IP Addresses (Whitelist)

### 1. Kubernetes API VIP (kube-vip)

| Параметр | Значение | Примечания |
|----------|---------|-----------|
| **IP Address** | `____________` | Например, 192.168.100.100 |
| **Purpose** | Kubernetes API HA VIP | Плавающий IP для control plane |
| **Announced by** | kube-vip (на одной из CP нод) | Gratuitous ARP |
| **DNS (optional)** | `____________` | Например, k8s-api.example.com |

**Как это работает:**
- kube-vip запущен на всех 3 control plane нодах
- Leader анонсирует VIP через gratuitous ARP
- При падении leader новый leader переанонсирует VIP
- SpoofGuard должен **разрешить** этот IP для всех CP нод

---

### 2. MetalLB IP Pool (Service LoadBalancer)

| Параметр | Значение | Примечания |
|----------|---------|-----------|
| **IP Range** | `____________` | Например, 192.168.100.200-220 |
| **Purpose** | LoadBalancer External IPs | Для Service type=LoadBalancer |
| **Announced by** | MetalLB speaker pods | Gratuitous ARP (L2 mode) |
| **Total IPs** | `____` | Например, 20 IP (200-220) |

**Как это работает:**
- При создании Service LoadBalancer MetalLB выделяет IP из pool
- MetalLB speaker (работает на нодах) анонсирует этот IP через ARP
- SpoofGuard должен **разрешить** все IP из pool для всех worker нод

---

## NSX UI Configuration Steps

### Вариант A: Whitelist через SpoofGuard Profile (рекомендуется)

**Шаги:**

1. **Открыть NSX Manager UI** → Login
2. **Перейти:** Security → SpoofGuard
3. **Найти профиль** для сегмента k8s-nodes:
   - Обычно называется `spoof-guard-profile-<segment-name>`
4. **Edit Profile** → **Allowed IP Addresses**
5. **Добавить IP:**
   - API VIP: `192.168.X.100`
   - MetalLB Pool: `192.168.X.200-220` (можно добавить диапазон или каждый IP отдельно)
6. **Save**
7. **Verify:** VM в сегменте могут анонсировать эти IP без блокировки

**Скриншот:**
- `[ ] Сохранён: research/nsx-analysis/screenshots/04-spoofguard-whitelist.png`

---

### Вариант B: Отключить SpoofGuard для портов k8s-нод (проще, но менее безопасно)

**Шаги:**

1. **NSX Manager UI** → Security → SpoofGuard
2. **Switching Profiles** → найти профиль для k8s-nodes segment
3. **Edit Profile** → **SpoofGuard** → **Disabled**
4. **Apply** to segment
5. ⚠️ **Задокументировать:** Для Prod нужно вернуть Enabled с whitelist

**Документация:**
- `[ ] Задокументировано`, что SpoofGuard disabled для PoC
- `[ ] Добавлено в TODO` для Prod: включить SpoofGuard с whitelist

---

## Whitelist Details (для каждого IP)

### API VIP

```yaml
IP: 192.168.X.100
MAC: <будет определён kube-vip динамически>
Purpose: Kubernetes API Server High Availability
Announced by: kube-vip (один из CP nodes в любой момент)
Required for: kubectl, kubeadm, kubelet → API connection
```

### MetalLB Pool

```yaml
IP Range: 192.168.X.200-220
MACs: <будут определены MetalLB speaker динамически>
Purpose: Service type=LoadBalancer External IPs
Announced by: MetalLB speaker pods (на worker nodes)
Required for: External access to K8s services (HTTP, HTTPS, TCP/UDP)
```

**Примеры использования:**
- `192.168.X.200` → Ingress Controller LoadBalancer IP (для HTTP/HTTPS)
- `192.168.X.201` → PostgreSQL Service External IP
- `192.168.X.202` → Redis Service External IP
- ...
- `192.168.X.220` → Запас

---

## Валидация

**После применения whitelist (или отключения SpoofGuard), проверить:**

### Тест 1: Secondary IP на VM

```bash
# На тестовой VM в сегменте k8s-nodes:
sudo ip addr add 192.168.X.100/24 dev ens192

# С другой VM пингануть:
ping 192.168.X.100
# [ ] ✅ Пингуется / [ ] ❌ Таймаут (SpoofGuard блокирует)

# Проверить ARP:
arp -n | grep 192.168.X.100
# [ ] ✅ Показывает MAC / [ ] ❌ Не показывает (блокировка)

# Очистка:
sudo ip addr del 192.168.X.100/24 dev ens192
```

### Тест 2: Gratuitous ARP

```bash
# На VM отправить gratuitous ARP:
sudo arping -c 3 -A -I ens192 192.168.X.100

# С другой VM прослушать:
sudo tcpdump -i ens192 -n arp | grep 192.168.X.100
# [ ] ✅ Видны ARP packets / [ ] ❌ Не видны (блокировка)
```

**Результаты валидации:**
- Тест 1: `[ ] ✅ Pass` / `[ ] ❌ Fail`
- Тест 2: `[ ] ✅ Pass` / `[ ] ❌ Fail`

**Дата валидации:** `___________`

---

## Troubleshooting

### Проблема: kube-vip не может анонсировать VIP

**Симптомы:**
- `kubectl` не может подключиться к API VIP
- `curl -k https://<VIP>:6443` таймаут
- kube-vip логи показывают `failed to send gratuitous ARP`

**Решение:**
1. Проверь, что VIP добавлен в SpoofGuard whitelist
2. Или отключи SpoofGuard для CP нод
3. Перезапусти kube-vip: `kubectl -n kube-system delete pod -l app=kube-vip`

---

### Проблема: MetalLB не может анонсировать LoadBalancer IP

**Симптомы:**
- Service LoadBalancer застрял в `<pending>` (нет External IP)
- Или External IP выделен, но недоступен извне
- MetalLB speaker логи показывают `failed to announce`

**Решение:**
1. Проверь, что MetalLB pool добавлен в SpoofGuard whitelist
2. Или отключи SpoofGuard для worker нод
3. Перезапусти MetalLB speaker: `kubectl -n metallb-system rollout restart daemonset speaker`

---

### Проблема: NSX UI не показывает опцию Allowed IP Addresses

**Причина:**
- Возможно, используется старая версия NSX или профиль не поддерживает whitelist

**Решение:**
- Вариант 1: Обнови NSX до версии с поддержкой whitelist (4.x+)
- Вариант 2: Отключи SpoofGuard для k8s-nodes segment (менее безопасно)
- Вариант 3: Используй CLI для настройки whitelist

---

## Security Considerations

### Для PoC (Dev/Test)

**Acceptable:**
- ✅ Отключить SpoofGuard полностью для k8s-nodes segment
- ✅ Whitelist всего диапазона (например, 192.168.X.0/24)

**Риски:**
- ⚠️ VM могут подменять IP друг друга (но в изолированном сегменте это low risk)

---

### Для Production

**Required:**
- ✅ SpoofGuard ENABLED
- ✅ Whitelist ТОЛЬКО конкретных IP (VIP + MetalLB pool)
- ✅ Регулярный audit whitelist (удалять неиспользуемые IP)

**Best Practices:**
- Использовать **минимальный** MetalLB pool (только сколько реально нужно сейчас)
- При добавлении новых LoadBalancer Services — добавлять IP в whitelist по необходимости
- Документировать каждый IP в whitelist (purpose, owner, date)

---

## Изменения и апдейты

| Дата | Изменение | IP Added/Removed | Автор |
|------|-----------|------------------|-------|
| `___________` | Первоначальная настройка | VIP + MetalLB pool | `___________` |
| | | | |

---

## References

- **NSX-T Documentation:** [SpoofGuard Configuration](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/)
- **kube-vip Documentation:** [ARP Mode](https://kube-vip.io/)
- **MetalLB Documentation:** [L2 Mode](https://metallb.universe.tf/concepts/layer2/)

---

**Этот документ — критичен для работы kube-vip и MetalLB!**
**Обновляй whitelist при добавлении новых VIP или LB IP.**
