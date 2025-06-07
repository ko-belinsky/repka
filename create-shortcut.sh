#!/bin/bash

[ -z "$1" ] && {
    yad --error --text="Не выбран файл!" --width=250
    exit 1
}

TARGET_FILE="$(realpath "$1")"  # Полный абсолютный путь к файлу
DESKTOP_DIR="$HOME/.local/share/applications"
TARGET_NAME=$(basename "$1")

# Функция для поиска существующих ярлыков
find_existing_desktop_files() {
    local exe_name=$(basename "$TARGET_FILE")
    local found_files=()
    
    # Ищем в папке .desktop файлы, где Exec содержит имя нашего файла
    for desktop_file in "$DESKTOP_DIR"/*.desktop; do
        [ -f "$desktop_file" ] || continue
        
        # Получаем строку Exec из .desktop файла
        exec_line=$(grep -E "^Exec=" "$desktop_file" | head -1)
        if [[ "$exec_line" == *"$exe_name"* ]]; then
            found_files+=("$desktop_file")
        fi
    done
    
    echo "${found_files[@]}"
}

# Проверяем существующие ярлыки
existing_files=$(find_existing_desktop_files)
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
        kbuildsycoca6 --noincremental 2>/dev/null
    fi
fi

# Определяем пути
[ -d "$HOME/Рабочий стол" ] && DESKTOP_PATH="$HOME/Рабочий стол" || DESKTOP_PATH="$HOME/Desktop"
AUTOSTART_DIR="$HOME/.config/autostart"

# Функция для проверки PortProton
check_portproton() {
    # Проверяем, установлен ли PortProton через flatpak (правильное имя приложения)
    if flatpak list | grep -q ru.linux_gaming.PortProton; then
        echo "flatpak run ru.linux_gaming.PortProton run '$TARGET_FILE'"
        return 0
    fi

    # Проверяем, установлен ли PortProton через репозитории
    if which portproton &>/dev/null; then
        echo "portproton '$TARGET_FILE'"
        return 0
    fi

    return 1
}

# Проверяем, является ли файл .exe и есть ли PortProton
if [[ "$TARGET_FILE" == *.exe ]]; then
    PORT_PROTON_CMD=$(check_portproton)
    if [ $? -eq 0 ]; then
        EXEC_COMMAND="$PORT_PROTON_CMD"
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

[ "$MENU" = "TRUE" ] || [ "$AUTOSTART" = "TRUE" ] && kbuildsycoca6 --noincremental 2>/dev/null
