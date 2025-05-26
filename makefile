PREFIX ?= $(HOME)/.local
BIN_DIR ?= $(PREFIX)/bin
NAUTILUS_SCRIPTS_DIR ?= $(PREFIX)/share/nautilus/scripts
KDE_SERVICES_DIR ?= $(PREFIX)/share/kio/servicemenus

detect_de:
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		echo "Обнаружен GNOME"; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		echo "Обнаружен KDE"; \
	else \
		echo "неизвестная DE"; \
	fi

install: detect_de
	@mkdir -p $(BIN_DIR) 2>/dev/null || true
	@install -m 755 ./create-shortcut.sh $(BIN_DIR)/create-shortcut.sh
	
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		mkdir -p $(NAUTILUS_SCRIPTS_DIR) 2>/dev/null || true; \
		ln -sfT $(BIN_DIR)/create-shortcut.sh "$(NAUTILUS_SCRIPTS_DIR)/Создать ярлык" 2>/dev/null || true; \
		echo "Добавлено в контекстное меню Nautilus"; \
		pkill -x nautilus 2>/dev/null || true; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		mkdir -p $(KDE_SERVICES_DIR) 2>/dev/null || true; \
		cp -f create-shortcut.desktop $(KDE_SERVICES_DIR)/ 2>/dev/null || true; \
		echo "Добавлено в контекстное меню Dolphin"; \
		kbuildsycoca6 2>/dev/null || true; \
	else \
		echo "Графическое окружение не определено, попробуйте ручную установку в ваш файловый менеджер"; \
	fi

uninstall:
	@rm -f $(BIN_DIR)/create-shortcut.sh 2>/dev/null || true
	@rm -f "$(NAUTILUS_SCRIPTS_DIR)/Создать ярлык" 2>/dev/null || true
	@rm -f $(KDE_SERVICES_DIR)/create-shortcut.desktop 2>/dev/null || true
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		pkill -x nautilus 2>/dev/null || true; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		kbuildsycoca6 2>/dev/null || true; \
	fi
	@echo "Удаление завершено"
