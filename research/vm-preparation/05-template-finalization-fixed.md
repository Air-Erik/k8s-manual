# Финализация VM Template для vSphere 8.2 с cloud‑init

> Обновлено: 2025‑10‑23  
> Назначение: сделать «золотой» шаблон Ubuntu, который корректно принимает **Cloud‑init metadata** и **Cloud‑init user‑data** из *VM Customization Specification* в vCenter.

---

## Важно (анти‑паттерны, которых следует избегать)

* ❌ Не создавайте файл `/etc/cloud/cloud-init.disabled` — он **полностью отключает** cloud‑init.  
* ❌ Не добавляйте в `/etc/cloud/cloud.cfg` блок `network: {config: disabled}` — это отключает управление сетью cloud‑init.  
* ❌ Не оставляйте в `/etc/netplan/` статические файлы (например, `01-netcfg.yaml`) — они помешают cloud‑init сгенерировать `50-cloud-init.yaml`.  
* ❌ Не кладите скрипты в несуществующие для cloud‑init директории вроде `/etc/cloud/cloud-init.d/`. Для одноразовых команд используйте `runcmd` в user‑data или каталоги `/var/lib/cloud/scripts/{per-once,per-instance,per-boot}`.

---

## Требования

* Ubuntu 22.04/24.04 (Server), интерфейс **vmxnet3**.  
* vCenter 8.0 U2/8.2 (UI с поддержкой cloud‑init спецификаций).  
* Пакеты: `cloud-init`, `open-vm-tools`.

---

## Шаг 0. Подготовить ВМ для правок шаблона

В vSphere сделайте **Clone to VM** из существующего Template (рекомендовано) или **Convert to VM**. Запустите ВМ и войдите в систему.

---

## Шаг 1. Базовые пакеты и источник данных

```bash
sudo apt-get update
sudo apt-get install -y cloud-init open-vm-tools

# Разрешаем нужные источники (включая VMware/GuestInfo)
sudo tee /etc/cloud/cloud.cfg.d/98-datasource.cfg >/dev/null <<'YAML'
datasource_list: [ VMware, OVF, NoCloud, None ]
YAML
```

Проверка:
```bash
dpkg -l | egrep 'cloud-init|open-vm-tools'
```

---

## Шаг 2. Убедиться, что cloud‑init включён

```bash
# Удалить маркер отключения, если есть
sudo rm -f /etc/cloud/cloud-init.disabled

# Разблокировать и включить юниты
sudo systemctl unmask cloud-init cloud-init-local cloud-config cloud-final
sudo systemctl enable  cloud-init cloud-init-local cloud-config cloud-final
```

---

## Шаг 3. Очистка состояния и сетевых следов

```bash
# Удалить кастомные netplan-файлы, чтобы cloud-init сгенерировал 50-cloud-init.yaml
sudo rm -f /etc/netplan/*.yaml

# Очистить состояние cloud-init «под шаблон»
sudo cloud-init clean --logs --machine
sudo rm -rf /var/lib/cloud
```

(Опционально: очистить кэш DHCP/udev, если когда‑то переименовывались интерфейсы.)

---

## Шаг 4. Завершение

```bash
sudo poweroff
```

В vSphere: **Convert to Template** (или оставьте как новый Template).

---

## Шаг 5. Создать VM Customization Specification (vCenter UI)

**Menu → Policies and Profiles → VM Customization → Create**  
Тип ОС: **Linux** → **Use cloud‑init**.

Вам будет предложено два поля: **Cloud‑init metadata** и **Cloud‑init user data**.  
Ниже — готовые примеры **разделённые на блоки**.

### 5.1 Cloud‑init **metadata** (без `#cloud-config`)

```yaml
instance-id: k8s-test-node-001
local-hostname: k8s-test-node

# netplan v2 — устойчивое именование NIC
network:
  version: 2
  ethernets:
    eth0:
      match: { driver: vmxnet3 }   # для vSphere
      set-name: eth0
      addresses: [10.246.10.250/24]
      gateway4: 10.246.10.1
      nameservers: { addresses: [172.17.10.3, 8.8.8.8] }
```

> Примечание: если IP должен выдаваться по DHCP, замените блок на `dhcp4: true` и уберите `addresses/gateway4/nameservers`.

### 5.2 Cloud‑init **user‑data** (обязательно начинается с `#cloud-config`)

```yaml
#cloud-config
fqdn: k8s-test-node.zeon-dev.local

users:
  - name: k8s-admin
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    ssh_authorized_keys:
      - ssh-ed25519 AAA... eric@REMOTE-VM

# пример: включить сервисы контейнерного рантайма/агента
runcmd:
  - systemctl enable containerd kubelet
  - systemctl start containerd
```

Сохраните спецификацию — теперь она станет доступна на шаге **Customize guest OS** при **Deploy from Template**.

---

## Шаг 6. Deploy from Template

Обычный мастер развертывания:
1. Выберите Template и ресурсы.
2. На шаге **Customize guest OS** отметьте **Use customization** и укажите созданную спецификацию.
3. Завершите мастер.

---

## Проверка после первого запуска ВМ

```bash
# Статус cloud-init
cloud-init status --long

# Логи применения
journalctl -u cloud-init -b | sed -n '1,160p'

# Что сгенерировано для netplan
sudo cat /etc/netplan/50-cloud-init.yaml

# Текущая сеть
ip -br a
ip route
```

Проверить, что vCenter реально передал данные через VMware Tools:
```bash
sudo vmtoolsd --cmd 'info-get guestinfo.metadata'    | head
sudo vmtoolsd --cmd 'info-get guestinfo.userdata'    | head
sudo vmtoolsd --cmd 'info-get guestinfo.userdata.encoding'
```

Полезные запросы cloud‑init:
```bash
cloud-init --version
cloud-init query --list-keys | head
cloud-init query v1.instance_id
cloud-init query v1.local_hostname
```

Ожидаемые признаки успеха:
* `cloud-init status` → `status: done`  
* Появился `/etc/netplan/50-cloud-init.yaml` и интерфейс поднялся.  
* В логах видно обработку `VMware` datasource и ваших блоков metadata/user‑data.

---

## Траблшутинг

* **`status: disabled`** — в шаблоне остался `/etc/cloud/cloud-init.disabled`. Удалить файл, затем `cloud-init clean` и выключить ВМ перед конвертацией в Template.
* **Сеть не поднялась** — проверьте имя интерфейса. Используйте `match: {driver: vmxnet3}` + `set-name: eth0` в *metadata*.
* **`guestinfo.*` пусто** — при деплое не была выбрана Customization Specification.
* **Конфликтует старый netplan** — удалите файлы в `/etc/netplan/`, повторите деплой.
* **Скрипты не выполняются** — используйте `runcmd` в user‑data или каталоги `/var/lib/cloud/scripts/...` вместо произвольных путей.

---

## Быстрый чек‑лист перед конвертацией в Template

- [ ] Установлены `cloud-init` и `open-vm-tools`  
- [ ] Нет `/etc/cloud/cloud-init.disabled`  
- [ ] В `/etc/cloud/cloud.cfg.d/98-datasource.cfg` указан `datasource_list: [ VMware, OVF, NoCloud, None ]`  
- [ ] Очищено состояние: `cloud-init clean --logs --machine` + пустой `/var/lib/cloud`  
- [ ] Нет статических файлов в `/etc/netplan/`  
- [ ] ВМ выключена штатно (`poweroff`)  
- [ ] Template создан/обновлён

---

## Приложение: Альтернатива без VM Customization (guestinfo.* вручную)

Если UI/права не позволяют создать спецификацию, можно задать данные напрямую в параметры ВМ:

*VM Options → Advanced → Configuration Parameters*

```
guestinfo.userdata             = <base64(#cloud-config ...)>
guestinfo.userdata.encoding    = base64
guestinfo.metadata             = <base64(yaml metadata ...)>
guestinfo.metadata.encoding    = base64
```

Проверка внутри гостя: `vmtoolsd --cmd 'info-get guestinfo.userdata'` и т.п.

---

Готово. Шаблон поддерживает cloud‑init и корректно настраивается из vCenter.
