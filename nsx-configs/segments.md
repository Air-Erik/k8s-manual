# NSX-T Network Configuration for Kubernetes Cluster

> **Статус:** 🟢 COMPLETED (Настройка завершена)
> **Дата обновления:** 2025-10-22
> **Оператор:** Ayrapetov_es

---

## Обзор

Этот документ фиксирует **финальные параметры** NSX-T сети для Kubernetes кластера.

**Решение:** ✅ **Создан отдельный T1 Gateway + новый сегмент** для полной изоляции k8s кластера

---

## Segment Information

| Параметр | Значение | Примечания |
|----------|---------|-----------|
| **Segment Name** | `k8s-zeon-dev-segment` | Имя сегмента в NSX-T |
| **Subnet (CIDR)** | `10.246.10.0/24` | Изолированная подсеть для k8s нод |
| **Gateway IP** | `10.246.10.1/24` | LIF на T1-k8s-zeon-dev |
| **DHCP Enabled** | `No` | Используем статические IP для предсказуемости |
| **DHCP Range** | `N/A` | DHCP не используется |
| **Tier-1 Gateway** | `T1-k8s-zeon-dev` | Отдельный T1 для k8s кластера |
| **Tier-0 Gateway** | `TO-GW` | Существующий T0 |
| **Transport Zone** | `nsx-overlay-transportzone` | Overlay TZ |

---

## IP Allocation Plan

**Всего доступных IP:** `254` (subnet size minus gateway/broadcast)

| IP Range / Single IP | Purpose | Status | Notes |
|---------------------|---------|--------|-------|
| `10.246.10.1` | Gateway (Tier-1) | Reserved | Автоматически |
| `10.246.10.10` | Control Plane Node 1 (cp-01) | Reserved | Статический IP |
| `10.246.10.11` | Control Plane Node 2 (cp-02) | Reserved | Статический IP |
| `10.246.10.12` | Control Plane Node 3 (cp-03) | Reserved | Статический IP |
| `10.246.10.20` | Worker Node 1 (w-01) | Reserved | Статический IP |
| `10.246.10.21` | Worker Node 2 (w-02) | Reserved | Статический IP |
| `10.246.10.22-30` | Worker Nodes (reserve, w-03..w-10) | Reserved | Запас для роста |
| `10.246.10.100` | API VIP (kube-vip) | Reserved | k8s-api.zeon-dev.local |
| `10.246.10.200-220` | MetalLB IP Pool | Reserved | Для Service type=LoadBalancer (20 IP) |
| `10.246.10.50-99` | Future Use | Available | Запас |

**✅ IP-план зафиксирован и готов к использованию!**

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
| **Primary DNS** | `172.17.10.3` |
| **Secondary DNS** | `8.8.8.8` |
| **Search Domain** | `zeon-dev.local` (опционально) |

**Метод настройки DNS:**
- `[x] Статически в Ubuntu (netplan/cloud-init)`
- `[ ] Через DHCP (NSX Segment DHCP Options)`

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

## NAT Configuration (настроено на T1-k8s-zeon-dev)

| NAT Rule | Type | Source | Translated IP | Notes |
|----------|------|--------|---------------|-------|
| `no_snat_to_internal` | No-SNAT | `10.246.10.0/24` | `N/A` | Доступ к внутренним сетям без NAT |
| `no_snat_to_vips` | No-SNAT | `10.246.10.0/24` | `172.16.50.192/27` | Доступ к VIP без hairpin проблем |
| `snat_to_internet` | SNAT | `10.246.10.0/24` | `172.16.50.170` | Egress в интернет |

**Проверка:**
```bash
# С VM:
curl ifconfig.me   # Должен вернуть 172.16.50.170 (SNAT IP)
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
| **Ping Internet** | `ping 8.8.8.8` | `[x] ✅ Pass` | Работает через SNAT 172.16.50.170 |
| **DNS Resolution** | `nslookup google.com` | `[x] ✅ Pass` | DNS 172.17.10.3 + 8.8.8.8 |
| **vCenter Access** | `curl -k https://<vcenter>` | `[x] ✅ Pass` | Для vSphere CSI |
| **Container Registry** | `curl -I https://registry.k8s.io` | `[x] ✅ Pass` | Для образов контейнеров |

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

- [x] ✅ Segment доступен (можно создать VM)
- [x] ✅ IP connectivity (ping gateway, ping между VM)
- [x] ✅ External connectivity (ping 8.8.8.8, DNS, vCenter)
- [x] ✅ NAT правила настроены (SNAT работает)
- [x] ✅ Route Advertisement включён (Connected Segments + NAT IPs)
- [x] ✅ Сетевая изоляция обеспечена (отдельный T1)
- [x] ✅ DNS работает
- [x] ✅ IP-план задокументирован

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
