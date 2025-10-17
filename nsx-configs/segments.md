# NSX-T Network Configuration for Kubernetes Cluster

> **Статус:** 🟡 Ожидает заполнения после настройки NSX-T
> **Дата обновления:** ___________
> **Оператор:** ___________

---

## Обзор

Этот документ фиксирует **финальные параметры** NSX-T сети для Kubernetes кластера.

**Решение:** `[ ] Используем существующий сегмент VIP-VM` / `[ ] Создан новый сегмент k8s-nodes-segment`

---

## Segment Information

| Параметр | Значение | Примечания |
|----------|---------|-----------|
| **Segment Name** | `____________` | Имя сегмента в NSX-T |
| **Subnet (CIDR)** | `____________` | Например, 192.168.100.0/24 |
| **Gateway IP** | `____________` | Например, 192.168.100.1 (на Tier-1) |
| **DHCP Enabled** | `Yes` / `No` | Используется ли DHCP |
| **DHCP Range** | `____________` | Если DHCP enabled, диапазон (иначе N/A) |
| **Tier-1 Gateway** | `____________` | Имя Tier-1, к которому подключен сегмент |
| **Tier-0 Gateway** | `____________` | Имя Tier-0 (для reference) |
| **Transport Zone** | `____________` | Имя Transport Zone |

---

## IP Allocation Plan

**Всего доступных IP:** `____` (subnet size minus gateway/broadcast)

| IP Range / Single IP | Purpose | Status | Notes |
|---------------------|---------|--------|-------|
| `192.168.X.1` | Gateway (Tier-1) | Reserved | Автоматически |
| `192.168.X.10` | Control Plane Node 1 (cp-01) | Reserved | Статический или DHCP reservation |
| `192.168.X.11` | Control Plane Node 2 (cp-02) | Reserved | Статический или DHCP reservation |
| `192.168.X.12` | Control Plane Node 3 (cp-03) | Reserved | Статический или DHCP reservation |
| `192.168.X.20` | Worker Node 1 (w-01) | Reserved | Статический или DHCP reservation |
| `192.168.X.21` | Worker Node 2 (w-02) | Reserved | Статический или DHCP reservation |
| `192.168.X.22-30` | Worker Nodes (reserve, w-03..w-10) | Reserved | Запас для роста |
| `192.168.X.100` | API VIP (kube-vip) | Reserved | k8s-api.example.com (опционально DNS) |
| `192.168.X.200-220` | MetalLB IP Pool | Reserved | Для Service type=LoadBalancer (20 IP) |
| `192.168.X.50-99` | Future Use | Available | Запас |

**Важно:** Заполни конкретные IP-адреса после настройки!

---

## MTU Configuration

| Layer | MTU Value | Notes |
|-------|-----------|-------|
| **NSX Overlay (Transport Nodes)** | `____` | Проверено в NSX UI → System → Fabric → Nodes |
| **VM vNIC (k8s nodes)** | `____` | Рекомендуется: Overlay MTU - 100 (обычно 1500) |
| **Cilium CNI (Pod network)** | `____` | Рекомендуется: VM MTU - 50 (обычно 1450) |

**Проверка:**
```bash
# Тест с VM:
ping -M do -s 1400 <node-IP>
# Результат: [ ] ✅ Проходит без фрагментации / [ ] ❌ Не проходит (нужно разобраться)
```

---

## DNS Configuration

| Параметр | Значение |
|----------|---------|
| **Primary DNS** | `____________` |
| **Secondary DNS** | `____________` |
| **Search Domain** | `____________` (опционально) |

**Метод настройки DNS:**
- `[ ] Через DHCP (NSX Segment DHCP Options)`
- `[ ] Статически в Ubuntu (netplan/cloud-init)`

---

## NTP Configuration (опционально для PoC, обязательно для Prod)

| Параметр | Значение |
|----------|---------|
| **NTP Server 1** | `____________` |
| **NTP Server 2** | `____________` |

**Метод настройки NTP:**
- `[ ] systemd-timesyncd`
- `[ ] chrony`
- `[ ] Не настроено (для PoC, настроить для Prod)`

---

## NAT Configuration (если используется)

| NAT Rule | Type | Source | Translated IP | Notes |
|----------|------|--------|---------------|-------|
| `____________` | SNAT | `192.168.X.0/24` | `<public-IP>` | Egress для k8s-нод |
| N/A | - | - | - | Если NAT не используется |

**Проверка:**
```bash
# С VM:
curl ifconfig.me   # Должен вернуть публичный IP (если SNAT настроен)
```

---

## DFW (Distributed Firewall) Rules

**Статус:** `[ ] Настроены` / `[ ] Не настроены (разрешён весь трафик)`

**Группа k8s-nodes:**
- **Имя группы в NSX:** `____________`
- **Критерий членства:** `[ ] По IP (192.168.X.10-30)` / `[ ] По VM тегам` / `[ ] По имени VM`

**Правила (в порядке приоритета):**

| Priority | Rule Name | Source | Destination | Ports | Action | Status |
|----------|-----------|--------|-------------|-------|--------|--------|
| `1000` | k8s-inter-node | k8s-nodes | k8s-nodes | Any (или 6443, 10250, etc.) | Allow | `[ ] ✅` |
| `1001` | k8s-nodeport-ingress | Any | k8s-nodes | 80, 443, 30000-32767 | Allow | `[ ] ✅` |
| `1002` | k8s-egress | k8s-nodes | Any | Any | Allow | `[ ] ✅` |

**Экспорт DFW правил:**
- `[ ] Сохранён в nsx-configs/dfw-rules.json`
- `[ ] Скриншот в research/nsx-analysis/screenshots/03-dfw-rules.png`

---

## SpoofGuard Configuration

**Статус:** `[ ] Enabled with whitelist` / `[ ] Disabled` / `[ ] Not configured`

**Если Enabled with whitelist:**

| Allowed IP Address / Range | Purpose | Notes |
|---------------------------|---------|-------|
| `192.168.X.100` | API VIP (kube-vip) | Для gratuitous ARP |
| `192.168.X.200-220` | MetalLB IP Pool | Для gratuitous ARP от MetalLB L2 |

**SpoofGuard Profile:**
- **Profile Name:** `____________`
- **Mode:** `Port Binding` / `Disabled`

**Документация whitelist:**
- `[ ] Сохранена в nsx-configs/spoofguard-whitelist.md`

---

## Routing Configuration

**Default Route:**
- `[ ] ✅ Настроен` (0.0.0.0/0 → Tier-0 через Tier-1)
- `[ ] ❌ Не настроен` (нужно проверить)

**Проверка:**
```bash
# С VM:
ping 8.8.8.8        # [ ] ✅ Работает / [ ] ❌ Не работает
traceroute 8.8.8.8  # Должен пройти через Gateway IP
```

---

## External Connectivity Test Results

| Test | Command | Result | Notes |
|------|---------|--------|-------|
| **Ping Internet** | `ping 8.8.8.8` | `[ ] ✅ Pass` / `[ ] ❌ Fail` | |
| **DNS Resolution** | `nslookup google.com` | `[ ] ✅ Pass` / `[ ] ❌ Fail` | |
| **vCenter Access** | `curl -k https://<vcenter>` | `[ ] ✅ Pass` / `[ ] ❌ Fail` | Для vSphere CSI |
| **Container Registry** | `curl -I https://registry.k8s.io` | `[ ] ✅ Pass` / `[ ] ❌ Fail` | Для образов контейнеров |

---

## Tanzu Coexistence (если применимо)

**Tanzu использует следующие сегменты:**
- `____________`
- `____________`

**Tanzu IP Pools (для избежания конфликтов):**

| Pool Name | IP Range | Purpose |
|-----------|----------|---------|
| `____________` | `____________` | Tanzu Pod CIDR |
| `____________` | `____________` | Tanzu SNAT |
| `____________` | `____________` | Tanzu LoadBalancer |

**Подтверждение:**
- `[ ] ✅ Наш MetalLB pool НЕ пересекается с Tanzu IP Pools`
- `[ ] ✅ Наш сегмент НЕ используется Tanzu Supervisor`

---

## Валидация (перед запуском Kubernetes)

**Все чек-листы из `research/nsx-analysis/09-validation-checklist.md` пройдены:**

- [ ] ✅ Segment доступен (можно создать VM)
- [ ] ✅ IP connectivity (ping gateway, ping между VM)
- [ ] ✅ External connectivity (ping 8.8.8.8, DNS, vCenter)
- [ ] ✅ DFW rules настроены (трафик разрешён)
- [ ] ✅ SpoofGuard настроен (ARP работает)
- [ ] ✅ MTU проверен (ping -M do -s 1400 работает)
- [ ] ✅ DNS работает
- [ ] ✅ IP-план задокументирован

**Дата валидации:** `___________`
**Валидатор:** `___________`

---

## Использование в Kubernetes Deployment

**Этот документ используется в следующих этапах:**

1. **Этап 0.2 (VM Preparation):**
   - Subnet → для настройки static IP или DHCP reservation
   - DNS → для cloud-init или netplan
   - MTU → для настройки VM vNIC

2. **Этап 1.1 (Cluster Bootstrap):**
   - API VIP → для kube-vip конфигурации
   - Control Plane IP → для kubeadm init

3. **Этап 1.2 (CNI Setup):**
   - MTU → для Cilium values.yaml

4. **Этап 1.4 (MetalLB Setup):**
   - MetalLB IP Pool → для IPAddressPool resource

5. **Этап 1.3 (Storage Setup):**
   - vCenter access → для vSphere CSI credentials

---

## Изменения и апдейты

| Дата | Изменение | Автор |
|------|-----------|-------|
| `___________` | Первоначальная настройка | `___________` |
| | | |

---

## Контакты

**NSX Admin:** `___________` (для вопросов по NSX-T)
**Kubernetes Admin:** `___________` (ты?)

---

**Этот документ — источник правды для сетевых параметров K8s кластера.**
**Обновляй его при любых изменениях в NSX-T!**
