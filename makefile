PREFIX ?= $(HOME)/.local
BIN_DIR ?= $(PREFIX)/bin
NAUTILUS_SCRIPTS_DIR ?= $(PREFIX)/share/nautilus/scripts
KDE_SERVICES_DIR ?= $(PREFIX)/share/kio/servicemenus

# Проверяем, существует ли файл перед установкой
CHECK_FILE_EXISTS := $(wildcard create-shortcut.sh)

detect_de:
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		echo "GNOME detected"; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		echo "KDE detected"; \
	else \
		echo "Unknown DE"; \
	fi

install: detect_de
	@mkdir -p $(BIN_DIR) 2>/dev/null || true
	@if [ -f "create-shortcut.sh" ]; then \
		install -m 755 create-shortcut.sh $(BIN_DIR)/create-shortcut.sh; \
		echo "Installed create-shortcut.sh to $(BIN_DIR)"; \
	else \
		echo "Error: create-shortcut.sh not found in current directory!"; \
		exit 1; \
	fi
	
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		mkdir -p $(NAUTILUS_SCRIPTS_DIR) 2>/dev/null || true; \
		ln -sfT $(BIN_DIR)/create-shortcut.sh "$(NAUTILUS_SCRIPTS_DIR)/Создать ярлык" 2>/dev/null || true; \
		echo "Installed for GNOME"; \
		pkill -x nautilus 2>/dev/null || true; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		mkdir -p $(KDE_SERVICES_DIR) 2>/dev/null || true; \
		cp -f create-shortcut.desktop $(KDE_SERVICES_DIR)/ 2>/dev/null || true; \
		echo "Installed for KDE"; \
		kbuildsycoca6 2>/dev/null || true; \
	else \
		echo "Desktop environment not recognized. Manual installation required."; \
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
	@echo "Uninstallation complete"
