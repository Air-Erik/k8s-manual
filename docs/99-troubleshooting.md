# Troubleshooting Guide

> **Статус:** 🟡 Living Document
> **Обновляется:** По мере выявления проблем

## Цель
Собрать частые проблемы и решения для быстрой диагностики.

---

## Проблема: Ноды в статусе NotReady

**Симптомы:**
```bash
kubectl get nodes
# NAME     STATUS     ROLES           AGE   VERSION
# node1    NotReady   control-plane   10m   v1.34.0
```

**Возможные причины:**
1. CNI не установлен или не запустился
2. kubelet не может достучаться до API
3. Проблемы с сертификатами

**Решение:**
```bash
# Проверить CNI поды:
kubectl get pods -n kube-system -l k8s-app=cilium

# Проверить kubelet логи на ноде:
sudo journalctl -u kubelet -f

# Проверить сертификаты:
sudo kubeadm certs check-expiration
```

---

## Проблема: API VIP недоступен

**Симптомы:**
```bash
curl -k https://<VIP>:6443
# Connection refused или timeout
```

**Возможные причины:**
1. kube-vip Static Pod не запустился
2. SpoofGuard блокирует ARP
3. DFW блокирует порт 6443

**Решение:**
```bash
# На control plane ноде проверить kube-vip:
sudo crictl ps | grep kube-vip
sudo crictl logs <kube-vip-container-id>

# Проверить ARP:
sudo tcpdump -i ens192 -n arp | grep <VIP>

# Проверить SpoofGuard в NSX UI
# Проверить DFW rules в NSX UI
```

---

## Проблема: MetalLB не выдаёт IP

**Симптомы:**
```bash
kubectl get svc my-service
# TYPE           EXTERNAL-IP   PORT(S)
# LoadBalancer   <pending>     80:30123/TCP
```

**Возможные причины:**
1. MetalLB поды не запустились
2. IPAddressPool неправильно настроен
3. L2Advertisement не создан
4. SpoofGuard блокирует IP из pool

**Решение:**
```bash
# Проверить MetalLB:
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l app=metallb

# Проверить IPAddressPool:
kubectl get ipaddresspool -n metallb-system
kubectl describe ipaddresspool -n metallb-system

# Проверить L2Advertisement:
kubectl get l2advertisement -n metallb-system
```

---

## Проблема: Ingress не маршрутизирует трафик

**Симптомы:**
```bash
curl http://myapp.example.com
# 404 Not Found или Connection refused
```

**Возможные причины:**
1. Ingress Controller не получил LoadBalancer IP
2. DNS не настроен
3. Ingress правила неправильно сконфигурированы
4. Backend Service не отвечает

**Решение:**
```bash
# Проверить Ingress Controller:
kubectl get svc -n ingress-nginx
kubectl get pods -n ingress-nginx

# Проверить Ingress:
kubectl get ingress -A
kubectl describe ingress my-ingress

# Проверить backend Service и Pods:
kubectl get svc,pods -n my-namespace

# Проверить DNS:
nslookup myapp.example.com
```

---

## Проблема: PVC в статусе Pending

**Симптомы:**
```bash
kubectl get pvc
# NAME      STATUS    VOLUME   CAPACITY   STORAGECLASS
# my-pvc    Pending                        default
```

**Возможные причины:**
1. vSphere CSI Driver не установлен
2. Secret с vCenter credentials неправильный
3. StorageClass не существует или не default
4. Датастор недоступен

**Решение:**
```bash
# Проверить CSI Driver:
kubectl get pods -n vmware-system-csi

# Проверить StorageClass:
kubectl get sc
kubectl describe sc default

# Проверить PVC events:
kubectl describe pvc my-pvc

# Проверить CSI логи:
kubectl logs -n vmware-system-csi -l app=vsphere-csi-controller
```

---

## Проблема: MTU/Connectivity issues

**Симптомы:**
- Медленная работа сети
- Таймауты при передаче больших данных
- Фрагментация пакетов

**Решение:**
```bash
# Проверить MTU на ноде:
ip link show ens192

# Проверить MTU в Cilium:
kubectl -n kube-system get cm cilium-config -o yaml | grep -i mtu

# Тест с большими пакетами:
ping -M do -s 1400 <target-IP>

# Исправить MTU в Cilium values.yaml и обновить
```

---

*TODO: Дополнить по мере выявления проблем.*
