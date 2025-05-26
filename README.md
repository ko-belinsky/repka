![Alt text](/preview.png?raw=true)


# Desktop Shortcut Creator

Маленькая программка для создания .desktop ярлыка для выбранного файла, через контекстное меню Nautilus/Dolphin в Альт Линукс.
Приложения .exe будут запускаться через PortProton, если он установлен.
Можно создать ярлык в меню приложений, на рабочем столе или добавить в автозагрузку (на выбор)

## Installation
```bash
git clone https://github.com/ko-belinsky/shortcut-creator.git
cd shortcut-creator
make install
```

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
   - yad
   - realpath (из coreutils)

   ALT Linux
```bash
   su -
   apt-get install yad coreutils
```
