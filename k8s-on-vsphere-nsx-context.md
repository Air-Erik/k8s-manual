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

## 10) Риски и меры

- **MTU/оверлей:** несогласованный MTU → таймауты. → Зафиксировать MTU end-to-end, задать в CNI.  
- **SpoofGuard/DFW:** блок VIP/ARP/NodePort. → Белые списки и группа `k8s-nodes`.  
- **IP-конфликты:** пул MetalLB/Ingress пересекается с DHCP/IPAM. → Резервирование, документация.  
- **Хранилище:** нестабильный NFS/датастор. → Выбор надёжного датастора/SPBM, тест PVC/PodDisruption.  
- **Ресурсы:** конкуренция с текущим Tanzu. → Параллельный сегмент/пулы, capacity-план.

---

## 11) Открытые вопросы (для последующих решений)

1. Какой **CNI** берём (Cilium/Calico)? Нужен ли kube-proxy replacement/Hubble?  
2. Какой **LB-путь**: MetalLB (L2/BGP) или Avi (AKO)?  
3. **Ingress**: NGINX vs Avi VS? Требуются ли wildcard-серты, ACME?  
4. **CSI**: vSphere CSI (дефолт) — какая SPBM-политика/датастор?  
5. **Логи/метрики**: Loki vs существующий OpenSearch, schema/парсинг?  
6. **CI/CD/GitOps**: нужен ли Argo CD/Flux на первом этапе?  
7. **Секьюрити**: PSA уровни, baseline/restricted, образ политики (Cosign/Trivy)?  
8. **DNS**: нужен ли ExternalDNS и какая зона/провайдер?  
9. **План миграции** от Tanzu: очередность, окна, откаты.

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

**Этот документ — “источник правды” для ассистентов.**  
Дальше на его основе будем принимать точечные решения (CNI/CSI/LB/Ingress), готовить манифесты и план миграции.
