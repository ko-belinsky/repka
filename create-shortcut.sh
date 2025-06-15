#!/bin/bash

# Кэш для проверки PortProton
PORT_PROTON_CACHE_FILE="$HOME/.cache/portproton_check"
PORT_PROTON_CACHE_TIMEOUT=3600 # 1 час

# Функция для проверки кэша PortProton
check_portproton_cache() {
    if [ -f "$PORT_PROTON_CACHE_FILE" ]; then
        local cache_time=$(stat -c %Y "$PORT_PROTON_CACHE_FILE")
        local current_time=$(date +%s)
        if (( current_time - cache_time < PORT_PROTON_CACHE_TIMEOUT )); then
            cat "$PORT_PROTON_CACHE_FILE"
            return 0
        fi
    fi
    return 1
}

# Функция для проверки PortProton с таймаутом
check_portproton() {
    # Сначала проверяем кэш
    local cached_result
    if cached_result=$(check_portproton_cache); then
        echo "$cached_result"
        return 0
    fi

    # Проверяем flatpak с таймаутом
    if timeout 2 flatpak list 2>/dev/null | grep -q ru.linux_gaming.PortProton; then
        echo "flatpak run ru.linux_gaming.PortProton run" > "$PORT_PROTON_CACHE_FILE"
        echo "flatpak run ru.linux_gaming.PortProton run"
        return 0
    fi

    # Проверяем системный portproton с таймаутом
    if timeout 2 which portproton &>/dev/null; then
        echo "portproton" > "$PORT_PROTON_CACHE_FILE"
        echo "portproton"
        return 0
    fi

    return 1
}

[ -z "$1" ] && {
    yad --error --text="Не выбран файл!" --width=250
    exit 1
}

TARGET_FILE="$(realpath "$1" 2>/dev/null || echo "$1")"  # Полный абсолютный путь к файлу
DESKTOP_DIR="$HOME/.local/share/applications"
TARGET_NAME=$(basename "$1")

# Оптимизированная функция для поиска существующих ярлыков
find_existing_desktop_files() {
    local exe_name=$(basename "$TARGET_FILE")
    local found_files=()
    
    # Используем find с -maxdepth для ограничения глубины поиска
    while IFS= read -r desktop_file; do
        [ -f "$desktop_file" ] || continue
        
        # Используем grep с -l для быстрого поиска
        if grep -l "Exec=.*$exe_name" "$desktop_file" &>/dev/null; then
            found_files+=("$desktop_file")
        fi
    done < <(find "$DESKTOP_DIR" -maxdepth 1 -name "*.desktop" -type f 2>/dev/null)
    
    echo "${found_files[@]}"
}

# Проверяем существующие ярлыки с таймаутом
existing_files=$(timeout 2 find_existing_desktop_files)
if [ -n "$existing_files" ]; then
    # Формируем список для отображения
    file_list=$(printf '%s\n' "${existing_files[@]}")
    
    # Диалог с предложением удалить
    yad --question \
        --title="Обнаружены существующие ярлыки" \
        --text="Найдены существующие ярлыки для этого исполняемого файла:\n\n$file_list\n\nУдалить их?" \
        --width=500 \
        --button="Удалить:0" \
        --button="Оставить:1"
    
    if [ $? -eq 0 ]; then
        for file in "${existing_files[@]}"; do
            rm -f "$file"
        done
        timeout 2 kbuildsycoca6 --noincremental 2>/dev/null
    fi
fi

# Определяем пути
[ -d "$HOME/Рабочий стол" ] && DESKTOP_PATH="$HOME/Рабочий стол" || DESKTOP_PATH="$HOME/Desktop"
AUTOSTART_DIR="$HOME/.config/autostart"

# Проверяем, является ли файл .exe и есть ли PortProton
if [[ "$TARGET_FILE" == *.exe ]]; then
    PORT_PROTON_CMD=$(check_portproton)
    if [ $? -eq 0 ]; then
        EXEC_COMMAND="$PORT_PROTON_CMD '$TARGET_FILE'"
    else
        yad --info --text="PortProton не найден в системе" --width=350
        EXEC_COMMAND="\"$TARGET_FILE\""
    fi
else
    EXEC_COMMAND="\"$TARGET_FILE\""
fi

# Форма с нормальными подписями кнопок
FORM_DATA=$(yad --form \
    --title="Создать ярлык для $TARGET_NAME" \
    --width=350 \
    --window-icon="list-add" \
    --field="Имя" "$TARGET_NAME" \
    --field="Описание" "" \
    --field="Иконка:FL" "" \
    --field="Категория:CB" "Utility!Development!Game!Graphics!AudioVideo!Office!Network!System" \
    --field="Меню приложений:CHK" TRUE \
    --field="Рабочий стол:CHK" FALSE \
    --field="Автозагрузка:CHK" FALSE \
    --button="Создать:0" \
    --button="Отмена:1" \
    --buttons-layout=spread
)

[ $? -ne 0 ] && exit 0

IFS='|' read -r NAME COMMENT ICON CATEGORY MENU DESKTOP AUTOSTART <<< "$FORM_DATA"

[ "$MENU" != "TRUE" ] && [ "$DESKTOP" != "TRUE" ] && [ "$AUTOSTART" != "TRUE" ] && exit 0

DESKTOP_FILENAME="${NAME// /_}.desktop"
DESKTOP_CONTENT="[Desktop Entry]
Version=1.0
Type=Application
Name=$NAME
Comment=$COMMENT
Exec=$EXEC_COMMAND
Icon=$ICON
Terminal=false
"

chmod +x "$TARGET_FILE" 2>/dev/null

if [ "$MENU" = "TRUE" ]; then
    echo -e "${DESKTOP_CONTENT}Categories=$CATEGORY\n" > "$DESKTOP_DIR/$DESKTOP_FILENAME"
    chmod +x "$DESKTOP_DIR/$DESKTOP_FILENAME"
fi

if [ "$DESKTOP" = "TRUE" ]; then
    echo -e "$DESKTOP_CONTENT" > "$DESKTOP_PATH/$DESKTOP_FILENAME"
    chmod +x "$DESKTOP_PATH/$DESKTOP_FILENAME"
fi

if [ "$AUTOSTART" = "TRUE" ]; then
    mkdir -p "$AUTOSTART_DIR"
    echo -e "${DESKTOP_CONTENT}Categories=$CATEGORY\n" > "$AUTOSTART_DIR/$DESKTOP_FILENAME"
    chmod +x "$AUTOSTART_DIR/$DESKTOP_FILENAME"
fi

[ "$MENU" = "TRUE" ] || [ "$AUTOSTART" = "TRUE" ] && timeout 2 kbuildsycoca6 --noincremental 2>/dev/null
