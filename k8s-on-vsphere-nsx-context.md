# Техническое задание (контекст)
**Проект:** Kubernetes-кластер на ВМ в VMware vSphere с underlay на NSX-T
**Версия документа:** 1.0 (точка входа для ассистентов)

---

## 1) Исходные данные

- **Инфраструктура:**
  - vSphere (vCenter + ESXi, DRS/HA доступны).
  - **NSX-T в эксплуатации** (Tier-0/1, сегменты, DFW/SpoofGuard, IPAM/DHCP при необходимости).
  - Есть существующий контур Tanzu/Supervisor (**будет жить параллельно**; миграция нагрузок позже).
  - Доступны NFS/vSAN/иные датасторы (точный выбор для PV позже).

- **Требования по кластеру:**
  - Чистый **Kubernetes (kubeadm)** на **виртуальных машинах** (без Tanzu).
  - Минимум 3 control-plane ноды (HA) + 2+ worker ноды.
  - **CNI, CSI, LoadBalancer, Ingress** — будут выбраны позже (пока «TBD»).
  - **NSX-T остаётся underlay-сетью** для ВМ (IP/маршрутизация/DFW/NAT), без NCP.

- **Ограничения/желания:**
  - Лицензии Tanzu не использовать.
  - Развёртывание по шагам, с возможностью быстрого PoC и последующего выхода в прод.
  - Сетевая часть должна быть понятной, с минимальным количеством магии.

---

## 2) Цели (желаемый результат)

- Развернуть **самостоятельный Kubernetes-кластер** на ВМ под vSphere, использующий сети NSX-T как underlay.
- Обеспечить:
  - **HA control-plane** (единый API-VIP).
  - Плоскую связность подов (требование K8s), **без** зависимости от Tanzu/NCP.
  - **Внешнюю публикацию сервисов** (через `Service: LoadBalancer` и/или `Ingress`).
  - **Динамические PVC** (через CSI; провиженер и политика хранения — TBD).
  - Наблюдаемость/логирование/бэкапы (минимальный базис).
- Подготовить документированные артефакты (манифесты/values/чек-листы) для тиражирования.

---

## 3) Не-цели (out of scope сейчас)

- Интеграция с NSX NCP (NSX как CNI) — **не планируется**.
- Мульти-тенантное управление кластерами из vSphere/Tanzu.
- Миграция всех текущих ворклоадов — позже, отдельной итерацией.
- Продвинутая Zero-Trust сеть/сегментация — будет после запуска базовой модели.

---

## 4) Нефункциональные требования и ограничения

- **Надёжность:** HA control-plane (3 ноды), отказоустойчивость VIP.
- **Производительность:** стандартная для K8s на ВМ; согласованный **MTU** по цепочке (NSX overlay ↔ VM ↔ CNI).
- **Безопасность:** базовые правила **NSX DFW** для группы `k8s-nodes` + **NetworkPolicy** в кластере; учёт **SpoofGuard**.
- **Обновляемость:** стандартные процедуры kubeadm (control-plane по одному, затем workers).
- **Совместимость:** без жёстких связок на версии NSX-T/Tanzu.

---

## 5) Высокоуровневая архитектура (набросок)

```
[ Users / Internet / Corp LAN ]
          |
      (DNS/Domain)
          |
      [Ingress]  <-- Ingress Controller (TBD: NGINX / Avi VS)
          |
   [Service: ClusterIP]
          |
        [Pods]  <-- CNI (TBD: Cilium/Calico) обеспечивает под-IPs и связность
          |
   [Worker Nodes (VMs)]  -- NSX-T Segment (L2/L3), DFW, NAT, Routing
          |
   [Control Plane (3x VMs)] -- kubeadm HA + API VIP (kube-vip)
          |
     [vSphere CSI] (TBD)
          |
    [Datastores / Policies]
```

- **NSX-T**: предоставляет сеть для **ВМ** (нод), маршрутизацию, DFW/SpoofGuard, IP-планы.
- **CNI**: строит сеть **подов** (под-IP, pod↔pod, pod↔node).
- **API-VIP**: через **kube-vip** (gratuitous ARP); VIP-IP должен быть разрешён в SpoofGuard.
- **LoadBalancer сервисы**:
  - **TBD**: `MetalLB (L2 или BGP)` **или** `Avi/NSX ALB + AKO`.
- **Ingress**: **TBD** (NGINX или Avi VS).
- **Хранилище**: **TBD** (vSphere CSI рекомендован).

---

## 6) Варианты/решения (пока TBD, выберем позже)

- **CNI:** `Cilium` (рекомендовано) или `Calico`.
- **LoadBalancer:** `MetalLB (L2 для простоты / BGP для зрелости)` или `Avi/NSX ALB (через AKO)`.
- **Ingress:** `NGINX Ingress` или `Avi VS`.
- **CSI (Storage):** `vSphere CSI` (дефолт), альтернативно `NFS Subdir External Provisioner`.
- **Observability:** `metrics-server`, `Prometheus+Grafana`, логи — `Loki` или существующий OpenSearch.
- **Backup/DR:** `Velero` (+ vSphere plugin при использовании vSphere CSI) и/или регулярные `etcdctl snapshot`.

---

## 7) Среды

- **PoC**: 1 control-plane (можно 3 сразу), 2 workers; MetalLB L2; минимальный Ingress; тестовые PVC.
- **Prod**: 3 control-plane, 3–N workers; DFW/NetworkPolicy; мониторинг/логи/бэкапы; GitOps (опционально).

---

## 8) Артефакты (что должны выдать на выходе)

- Шаблон/гайд по подготовке **VM-шаблонов** (Ubuntu LTS, cloud-init/Customization Spec, sysctl, swap off).
- Манифест **kube-vip** (Static Pod/DS) с описанием VIP и интерфейса.
- Манифесты/values для **CNI** (MTU, kube-proxy replacement — если Cilium).
- Манифесты **LoadBalancer-провайдера** (MetalLB IPAddressPool/L2Advertisement **или** AKO-профили для Avi).
- Манифест **Ingress** (базовый).
- Секрет/конфиг и **StorageClass** для **CSI** (если vSphere CSI).
- Базовые **NSX DFW** правила и чек-лист **SpoofGuard/MTU/IPAM**.
- Чек-лист запуска/проверок + runbook обновлений/резервного копирования.

---

## 9) Критерии успеха

- Кластер доступен по **API-VIP**, `kubectl get nodes` показывает все ноды **Ready**.
- Развёрнут тестовый `Deployment` + `Service: LoadBalancer` (получает внешний IP) + `Ingress` (HTTP/HTTPS доступ извне).
- PVC создаются динамически по **дефолтному StorageClass**; I/O стабилен.
- Мониторинг показывает метрики, логи собираются; Velero/etcd-snapshot проверены.
- Отсутствуют сетевые плавающие проблемы (MTU, ARP/SpoofGuard, DFW).

---

## 10) Риски и меры митигации

### Риск 1: MTU несоответствие (Fragmentation/Timeouts)
**Проблема:** Несогласованный MTU между NSX overlay (обычно 1600 из-за инкапсуляции), VM-интерфейсом и CNI приводит к фрагментации пакетов, таймаутам, медленной работе.

**Меры:**
- Зафиксировать MTU **end-to-end**:
  - NSX Transport Node overlay MTU: обычно 1600
  - VM vNIC MTU: 1500 (если overlay 1600, VM должна быть ≤1500 для запаса на инкапсуляцию)
  - Cilium CNI MTU: задать явно в `values.yaml` (например, 1450 для запаса на VXLAN/Geneve)

**Чек-лист:**
```bash
# На ноде проверить MTU интерфейса:
ip link show ens192

# Проверить MTU в Cilium:
kubectl -n kube-system get cm cilium-config -o yaml | grep -i mtu

# Тест связности с большими пакетами (без фрагментации):
ping -M do -s 1400 <IP-другой-ноды>
```

**Документация:** Создать `docs/mtu-checklist.md` с замерами.

---

### Риск 2: SpoofGuard блокирует VIP и MetalLB ARP
**Проблема:** NSX SpoofGuard по умолчанию блокирует ARP-ответы с MAC/IP, не совпадающими с изначальной регистрацией VM. kube-vip и MetalLB используют gratuitous ARP для анонса VIP — это может быть заблокировано.

**Меры:**
- Добавить **VIP API** и **диапазон MetalLB** в SpoofGuard whitelist для группы `k8s-nodes`.
- **Альтернатива:** отключить SpoofGuard на уровне Segment Port для k8s-нод (менее безопасно, но проще для PoC).

**Чек-лист:**
```bash
# На control plane ноде проверить ARP-анонс VIP:
sudo tcpdump -i ens192 -n arp | grep <VIP-IP>

# Проверить доступность VIP с другой ноды:
ping <VIP-IP>
curl -k https://<VIP-IP>:6443/version
```

**Документация:** В `docs/01-nsx-network-setup.md` добавить шаги по настройке SpoofGuard.

---

### Риск 3: DFW блокирует inter-node или pod-трафик
**Проблема:** Distributed Firewall может блокировать трафик между нодами (API, kubelet, CNI overlay) или NodePort-сервисы.

**Меры:**
- Создать группу `k8s-nodes` (по IP или VM-тегам).
- Создать DFW-правила **до дефолтных deny-правил**:
  - **Allow**: `k8s-nodes` → `k8s-nodes` (любые порты, или специфично: 6443, 10250, 2379-2380, 4240, 8472)
  - **Allow**: `Any` → `k8s-nodes` на порты NodePort (30000-32767) и Ingress (80, 443)
  - **Allow**: `k8s-nodes` → `Internet/Corp` (для apt, container registry, external API)

**Чек-лист:**
```bash
# Проверить доступность API между нодами:
curl -k https://<control-plane-IP>:6443/version

# Проверить kubelet port:
nc -zv <worker-IP> 10250

# Проверить Cilium VXLAN (если используется):
nc -zvu <worker-IP> 8472
```

**Документация:** `nsx-configs/dfw-rules.json` — экспорт правил из NSX UI.

---

### Риск 4: IP-конфликты (MetalLB Pool vs DHCP/IPAM)
**Проблема:** Диапазон MetalLB пересекается с DHCP pool или статически назначенными IP → конфликты, недоступность сервисов.

**Меры:**
- **Зарезервировать** диапазон MetalLB в NSX IPAM (если используется).
- **Документировать** IP-план в `docs/01-nsx-network-setup.md`.
- Использовать отдельную подсеть для MetalLB (опционально, если есть Tier-1 маршрутизация).

**Чек-лист:**
```bash
# Перед выделением IP проверить, что они свободны:
for ip in {200..220}; do ping -c 1 -W 1 192.168.100.$ip && echo "$ip USED"; done

# После создания Service LoadBalancer проверить выделение:
kubectl get svc -A -o wide | grep LoadBalancer
```

---

### Риск 5: Нестабильное хранилище (NFS/vSAN latency)
**Проблема:** Высокая latency или нестабильность датастора → pod eviction, потеря данных, slow I/O.

**Меры:**
- Выбрать **надёжный датастор** с SPBM политикой (например, vSAN с FTT=1 или выделенный NFS).
- Тестировать производительность с `fio` benchmark в pod.
- Настроить **PodDisruptionBudget** для stateful workloads.
- Включить **Velero** для бэкапа PVC.

**Чек-лист:**
```bash
# Создать тестовый PVC и pod с fio:
kubectl apply -f manifests/examples/storage-test.yaml

# Проверить latency записи:
kubectl exec -it storage-test-pod -- fio --name=write-test --rw=write --bs=4k --size=1G --numjobs=1
```

**Документация:** `docs/05-storage-setup.md` — бенчмарки и выбор датастора.

---

### Риск 6: Конкуренция ресурсов с Tanzu/Supervisor
**Проблема:** Новый k8s-кластер и Tanzu делят один cluster/pool ESXi → resource contention (CPU/RAM/Storage).

**Меры:**
- Использовать **отдельный Resource Pool** в vSphere для k8s-нод (опционально).
- Проверить доступные ресурсы перед созданием ВМ:
  ```bash
  # Capacity planning: минимум для PoC:
  # 3 CP: 3x2 vCPU, 3x8 GB RAM = 6 vCPU, 24 GB RAM
  # 2 W:  2x4 vCPU, 2x16 GB RAM = 8 vCPU, 32 GB RAM
  # Итого: 14 vCPU, 56 GB RAM + storage
  ```
- Установить **Resource Reservations** для критичных k8s-нод (опционально).

**Документация:** Capacity план в `docs/02-vm-preparation.md`.

---

### Риск 7: kubeadm/containerd версионная несовместимость
**Проблема:** Новая Ubuntu 24.04, Kubernetes 1.34 → возможны баги или deprecated API.

**Меры:**
- Использовать **официальные репозитории** Kubernetes (apt.kubernetes.io).
- Фиксировать версии пакетов: `kubeadm=1.34.x`, `kubelet=1.34.x`, `kubectl=1.34.x`.
- Проверять совместимость containerd с Kubernetes на официальном [CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG).

**Чек-лист:**
```bash
# Проверить версии после установки:
kubeadm version
kubelet --version
containerd --version

# Проверить CRI socket:
crictl info
```

**Документация:** `docs/02-vm-preparation.md` — установка конкретных версий.

---

## 11) Открытые вопросы (для последующих решений)

**Решённые вопросы (см. раздел 16):**
- ✅ **CNI**: Cilium (с kube-proxy replacement и Hubble для observability)
- ✅ **LoadBalancer**: MetalLB в L2 режиме для PoC
- ✅ **Ingress**: NGINX Ingress Controller
- ✅ **CSI**: vSphere CSI Driver

**Всё ещё TBD:**

1. **Конкретные NSX-T параметры:**
   - Имя Segment для k8s-нод
   - Подсеть VM (например, 192.168.100.0/24)
   - API VIP конкретный IP
   - MetalLB IP Pool диапазон
   - MTU значение (1500 или 9000)
   - DNS servers

2. **vSphere CSI — SPBM политика и датастор:**
   - Какой датастор использовать для PV? (vSAN/NFS/VMFS)
   - Нужна ли отдельная SPBM политика?
   - Требования к производительности/FTT

3. **TLS сертификаты для Ingress:**
   - Wildcard сертификаты или per-service?
   - Использовать ли cert-manager + Let's Encrypt (ACME)?
   - Корпоративный CA?

4. **Логи и расширенный мониторинг:**
   - metrics-server для начала, но позже:
   - Prometheus + Grafana?
   - Логи: Loki или интеграция с существующим OpenSearch?
   - Alerting (Alertmanager/Opsgenie)?

5. **CI/CD и GitOps:**
   - Нужен ли Argo CD или Flux на первом этапе?
   - Или пока ручной `kubectl apply`?

6. **Security базлайн:**
   - PSA (Pod Security Admission) — какой уровень? (baseline/restricted)
   - Нужен ли image scanning (Trivy) и signing (Cosign)?
   - NetworkPolicy — какие дефолтные политики?

7. **External DNS:**
   - Нужен ли ExternalDNS для автоматического создания DNS записей?
   - Какая зона и DNS провайдер? (Route53/CloudDNS/корпоративный)

8. **План миграции от Tanzu:**
   - Приоритизация workloads
   - Временные окна
   - Процедуры отката
   - **Отложено до этапа 3**

> **Действие:** Эти вопросы будут решены итеративно в процессе реализации. Критичные (NSX-T параметры, датастор) — на этапе 0-1.

---

## 12) План работ (итеративно)

- **Этап 0 — Подготовка**: сегмент NSX-T, IP-план (VIP, LB-пул), шаблоны ВМ, DFW базовые правила, MTU чек.
- **Этап 1 — PoC**: 3 CP + 2 W; kubeadm init + kube-vip; CNI; LB (MetalLB/Аvi); Ingress; CSI; тестовый workload.
- **Этап 2 — Prod-жёсткость**: мониторинг/логи, Velero, NetworkPolicy, PSA, GitOps, бэкап-процедуры.
- **Этап 3 — Миграция**: по сервисам/неймспейсам с валидацией и откатами; декомиссия Tanzu позднее.

---

## 13) Чек-лист приёмки (минимум)

- [ ] API-VIP отвечает, все control-plane **Ready**.
- [ ] Все workers **Ready**.
- [ ] PVC динамически создаётся, pod читает/пишет.
- [ ] `Service: LoadBalancer` получает внешний IP, доступ есть.
- [ ] `Ingress` маршрутизирует по host/path.
- [ ] Метрики/логи видны; Velero/etcd-snapshot проверены.
- [ ] DFW/SpoofGuard корректно настроены, нет блокировок.
- [ ] Документация и артефакты актуальны.

---

## 14) Глоссарий (кратко)

- **Underlay (NSX-T для ВМ):** сетевая основа для нод (IP/маршруты/DFW).
- **CNI:** сетевой плагин подов (под-IP и связность).
- **CSI:** провиженер хранилища для PVC.
- **kube-vip:** виртуальный IP для API (HA без внешнего LB).
- **MetalLB/Avi:** выдача внешних IP для `Service: LoadBalancer`.
- **Ingress:** L7-маршрутизация HTTP(S) к сервисам.
- **PSA/NetworkPolicy:** политика безопасности подов/трафика.

---

## 15) Конкретные параметры инфраструктуры

### Версии компонентов
- **Kubernetes:** `1.34.x` (последняя стабильная minor-версия)
- **ОС нод:** `Ubuntu 24.04 LTS`
- **vSphere:** `8.0.3.00500`
- **NSX-T:** `4.2.3.0.0`
- **Container Runtime:** `containerd` (последняя стабильная)

### Размеры ВМ (для DEV/PoC кластера)

**Control Plane ноды (3 шт):**
- **vCPU:** 2 (минимум для PoC, 4 для Prod)
- **RAM:** 8 ГБ (минимум для PoC, 16 ГБ для Prod)
- **Disk:** 80 ГБ (thin provision)
- **Network:** 1x vNIC (на NSX-T сегменте k8s-nodes)

**Worker ноды (2+ шт для PoC, 3+ для Prod):**
- **vCPU:** 4
- **RAM:** 16 ГБ
- **Disk:** 100 ГБ (thin provision)
- **Network:** 1x vNIC (на NSX-T сегменте k8s-nodes)

> **Примечание:** Для Prod-кластера Control Plane ноды увеличиваются до 4 vCPU / 16 ГБ RAM.

### IP-адресация и сетевые параметры

> **Важно:** Конкретные IP-адреса будут заданы при настройке NSX-T сегмента (отдельная задача).

**Kubernetes Internal Networking:**
- **Pod CIDR:** `10.244.0.0/16` (по умолчанию для Cilium, можно изменить)
- **Service CIDR:** `10.96.0.0/12` (стандартный диапазон Kubernetes)

**NSX-T Segment для k8s-нод:**
- **Имя сегмента:** `TBD` (будет задано при настройке NSX)
- **Подсеть для VM:** `TBD` (например, 192.168.100.0/24)
- **Gateway:** `TBD` (например, 192.168.100.1)
- **DNS Servers:** `TBD` (корпоративные или 8.8.8.8/8.8.4.4)
- **MTU:** `TBD` (обычно 1500 или 9000 для Jumbo Frames, согласовать с NSX overlay)

**Kubernetes API VIP:**
- **API VIP адрес:** `TBD` (из диапазона подсети k8s-nodes, резервируется в IPAM/SpoofGuard)
- **kube-vip интерфейс:** `ens192` (или актуальное имя интерфейса в Ubuntu 24.04)

**MetalLB IP Pool (для Service LoadBalancer):**
- **Диапазон:** `TBD` (например, 192.168.100.200-192.168.100.220)
- **Режим:** `L2` (ARP-based)
- **Требование:** IP должны быть из той же подсети, что и ноды, или маршрутизируемы через NSX Tier-0/1

> **Действие:** Все IP-параметры будут конкретизированы в документе по настройке NSX-T сети (отдельный артефакт).

### Хранилище (Storage)
- **Datastore для VM:** `TBD` (указать при создании VM в vSphere)
- **Datastore для vSphere CSI PV:** `TBD` (может быть тот же или отдельный, с соответствующей SPBM политикой)
- **Тип датастора:** vSAN / NFS / VMFS (будет определён при настройке)

---

## 16) Решения для PoC/Dev-кластера (зафиксировано)

Для ускорения разработки и последующего тиражирования в Prod приняты следующие решения:

| Компонент | Решение | Обоснование |
|-----------|---------|-------------|
| **CNI** | **Cilium** (latest stable) | Современный eBPF-based CNI с встроенным observability (Hubble), NetworkPolicy, и возможностью kube-proxy replacement. |
| **LoadBalancer** | **MetalLB** (L2 mode) | Простой для PoC, не требует BGP-настроек на NSX. Для Prod возможен переход на BGP или Avi/NSX ALB. |
| **Ingress** | **NGINX Ingress Controller** | Стандарт де-факто, зрелый, широко документирован. |
| **CSI** | **vSphere CSI Driver** | Нативная интеграция с vSphere, поддержка динамических PV, снапшотов, Velero. |
| **Observability** | **metrics-server** (базовый) | Минимум для `kubectl top`. Позже добавим Prometheus/Grafana/Loki. |
| **API VIP** | **kube-vip** (Static Pod или DaemonSet) | Простое решение для HA API без внешнего LB, работает через ARP (требует разрешения в SpoofGuard). |
| **Backup** | **Velero** + **etcdctl snapshot** | Velero для namespace/PV backup (с vSphere plugin); etcdctl для точечных бэкапов control plane. |

> **Примечание:** Решения для Prod могут эволюционировать (например, MetalLB L2 → BGP, или добавление Avi/NSX ALB).

---

## 17) Структура репозитория

Для упрощения навигации и воспроизводимости решений репозиторий будет организован следующим образом:

```
k8s-manual/
├── README.md                          # Обзор проекта, быстрый старт
├── k8s-on-vsphere-nsx-context.md      # Этот документ (источник правды)
│
├── docs/                              # Документация и мануалы
│   ├── 01-nsx-network-setup.md        # Настройка NSX-T сегмента, IP-плана, DFW
│   ├── 02-vm-preparation.md           # Создание VM-шаблонов, cloud-init, sysctl
│   ├── 03-cluster-bootstrap.md        # kubeadm init, kube-vip, join workers
│   ├── 04-cni-setup.md                # Установка и настройка Cilium
│   ├── 05-storage-setup.md            # vSphere CSI Driver, StorageClass
│   ├── 06-metallb-setup.md            # MetalLB установка и конфигурация
│   ├── 07-ingress-setup.md            # NGINX Ingress Controller
│   ├── 08-observability-setup.md      # metrics-server, Prometheus (опционально)
│   ├── 09-backup-setup.md             # Velero, etcd snapshot процедуры
│   ├── 10-testing-validation.md       # Тестовые workloads и чек-листы
│   └── 99-troubleshooting.md          # Частые проблемы и решения
│
├── manifests/                         # Все Kubernetes манифесты
│   ├── kube-vip/                      # kube-vip Static Pod / DaemonSet
│   ├── cilium/                        # Cilium Helm values или manifests
│   ├── metallb/                       # MetalLB IPAddressPool, L2Advertisement
│   ├── ingress-nginx/                 # NGINX Ingress Helm values или manifests
│   ├── vsphere-csi/                   # vSphere CSI secret, deployment, StorageClass
│   ├── observability/                 # metrics-server, Prometheus (опционально)
│   ├── backup/                        # Velero install configs
│   ├── security/                      # NetworkPolicy примеры, PSA configs
│   └── examples/                      # Тестовые Deployments, Services, Ingress
│
├── scripts/                           # Вспомогательные скрипты
│   ├── prepare-vm.sh                  # Скрипт подготовки Ubuntu VM (sysctl, swap, containerd)
│   ├── bootstrap-control-plane.sh     # Автоматизация kubeadm init + kube-vip
│   ├── join-worker.sh                 # Скрипт для join worker нод
│   ├── etcd-backup.sh                 # Скрипт резервного копирования etcd
│   └── cluster-upgrade.sh             # Скрипт обновления кластера (kubeadm upgrade)
│
├── nsx-configs/                       # Экспорты/описания NSX-T конфигураций
│   ├── dfw-rules.json                 # DFW правила для группы k8s-nodes (экспорт или описание)
│   ├── segments.md                    # Описание созданных сегментов
│   └── spoofguard-whitelist.md        # Список IP для SpoofGuard whitelist (VIP, MetalLB)
│
└── vm-templates/                      # Ресурсы для подготовки VM
    ├── cloud-init.yaml                # cloud-init конфиг для Ubuntu
    ├── vsphere-customization-spec.md  # Описание vSphere Customization Spec
    └── packages-list.txt              # Список пакетов для установки на VM
```

### Принципы работы с репозиторием:
1. **Документация (`docs/`)** — пошаговые мануалы для человека-оператора.
2. **Манифесты (`manifests/`)** — декларативные конфигурации, применяются через `kubectl apply`.
3. **Скрипты (`scripts/`)** — автоматизация повторяющихся задач (подготовка VM, bootstrap, backup).
4. **NSX конфиги (`nsx-configs/`)** — фиксация сетевых настроек для воспроизводимости.
5. **VM шаблоны (`vm-templates/`)** — всё для создания базовых образов нод.

---

## 18) Роли и процесс работы

### Роль AI Team Lead (этот ассистент)
- Формирование структуры задач и подзадач.
- Создание инструкций (`.md` файлов) для AI-исполнителей.
- Валидация артефактов (манифестов, документации).
- Координация между этапами работы.
- Отслеживание прогресса и рисков.

### Роль AI-исполнителей
- Получают конкретные задачи в формате `.md` инструкций.
- Создают артефакты: манифесты, скрипты, документацию.
- Работают в рамках зафиксированных решений (раздел 16).
- Не имеют прямого доступа к инфраструктуре.

### Роль оператора-человека
- **Физическое выполнение:** создание VM, применение манифестов, настройка NSX-T.
- **Валидация:** проверка работоспособности после каждого этапа.
- **Feedback:** сообщение о проблемах для корректировки инструкций.

### Процесс координации
1. **Team Lead создаёт задачу** → файл `docs/XX-task-name.md` с инструкциями.
2. **AI-исполнитель реализует** → создаёт/обновляет манифесты, скрипты, документацию.
3. **Оператор применяет** → выполняет инструкции на реальной инфраструктуре.
4. **Валидация** → оператор проверяет результат, возвращает статус.
5. **Итерация или следующий этап** → в зависимости от результата.

> **Важно:** Все манифесты должны быть **декларативными** и **воспроизводимыми** для последующего развёртывания Prod-кластера.

---

**Этот документ — "источник правды" для ассистентов.**
Дальше на его основе будем создавать конкретный план работ и инструкции для исполнителей.
