# Backup Setup (Velero + etcd snapshots)

> **Статус:** 🔴 TODO
> **Ответственный:** AI-исполнитель
> **Зависимости:** Кластер полностью работает, CSI настроен (05)

## Цель
Настроить резервное копирование кластера через Velero и etcd snapshots.

## Артефакты на выходе
- Velero манифесты/конфигурация в `manifests/backup/`
- Скрипт `scripts/etcd-backup.sh` для ручных snapshot
- Инструкции по восстановлению
- Расписание автоматических бэкапов (CronJob или Velero Schedule)

## Задачи
- [ ] Установить Velero CLI
- [ ] Настроить backend для Velero (S3-compatible или vSphere plugin)
- [ ] Установить Velero в кластер
- [ ] Создать тестовый backup namespace/PVC
- [ ] Проверить restore
- [ ] Создать скрипт для etcd snapshot на Control Plane нодах
- [ ] (Опционально) Настроить автоматическое расписание

## Инструкции

*TODO: Будут добавлены AI-исполнителем.*

## Проверка
```bash
velero backup create test-backup --include-namespaces default
velero backup describe test-backup
velero restore create --from-backup test-backup
# etcd:
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db
```
