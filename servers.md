# Серверы

## 1. danilchenov.fvds.ru — 5.35.99.93

Основной рабочий сервер. **Claude имеет прямой доступ** через MCP `ropbot ssh_run`.

- Ubuntu, диск 79 ГБ (занято 15 %), git и jq есть, sqlite3 нет
- SSH-ключ для исходящих: `~/.ssh/relay` (публичный — `relay.pub`)
- Docker + containerd
- Каталоги: `/opt/ropbot` (Виртуальный РОП), `/opt/knowledge` (этот реестр)
- Часовой пояс: Europe/Moscow

## 2. 195.2.74.207 — v3137506

Сервер сайта и страницы-прокладки. **Claude имеет root-доступ с 20.08.2026** —
через ропбот-сервер: `ssh -i ~/.ssh/relay root@195.2.74.207`.
hostname: `v3137506.hosted-by-vdsina.ru`.

- `/var/www/mes.autosender.ru/index.html` — страница подписки
- nginx + certbot, сертификат Let's Encrypt до 15.11.2026
- DNS: `mes.autosender.ru` → 195.2.74.207

**Как отозвать доступ:** удалить строку с ключом `root@danilchenov.fvds.ru`
из `/root/.ssh/authorized_keys` на 195.2.74.207.

Выданный ключ:
```
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICJdAl2AiNbjhqL7l4JJ4yMGpDAiwp025/u8RhW4jaU root@danilchenov.fvds.ru' >> ~/.ssh/authorized_keys
```

## Известные особенности

- Часы контейнера Claude могут врать на сутки. **Дату всегда брать с сервера**
  командой `date`, а не из окружения.
