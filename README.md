# Desktop Shortcut Creator

## Installation
```bash
git clone https://github.com/ko-belinsky/shortcut-creator.git
cd shortcut-creator
make install```

1. При запуске `make install`:
   - Определяет DE (GNOME/KDE)
   - Устанавливает скрипт в `~/.local/bin`
   - Для GNOME создает пункт в контекстном меню Nautilus
   - Для KDE создает пункт в контекстном меню Dolphin
   - Перезапускает файловый менеджер для применения изменений

2. При запуске `make uninstall`:
   - Удаляет все установленные файлы
   - Обновляет кеш меню

3. Зависимости:
   - `yad` (должен быть установлен)
   - `realpath` (из coreutils)

Для установки зависимостей в Ubuntu/Debian:
```bash
sudo apt install yad coreutils```
   ALT Linux
```su -
   apt-get install yad coreutils```
