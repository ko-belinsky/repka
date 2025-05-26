PREFIX ?= $(HOME)/.local
BIN_DIR ?= $(PREFIX)/bin
NAUTILUS_SCRIPTS_DIR ?= $(PREFIX)/share/nautilus/scripts
KDE_SERVICES_DIR ?= $(PREFIX)/share/kservices5/ServiceMenus

detect_de:
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		echo "GNOME detected"; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		echo "KDE detected"; \
	else \
		echo "Unknown DE"; \
	fi

install: detect_de
	mkdir -p $(BIN_DIR)
	install -m 755 src/create-shortcut.sh $(BIN_DIR)/create-shortcut.sh
	
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		mkdir -p $(NAUTILUS_SCRIPTS_DIR); \
		ln -sf $(BIN_DIR)/create-shortcut.sh "$(NAUTILUS_SCRIPTS_DIR)/Создать ярлык"; \
		echo "Installed for GNOME"; \
		pkill -x nautilus || true; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		mkdir -p $(KDE_SERVICES_DIR); \
		cp src/kde/create-shortcut.desktop $(KDE_SERVICES_DIR); \
		echo "Installed for KDE"; \
		kbuildsycoca6 || true; \
	else \
		echo "Desktop environment not recognized. Manual installation required."; \
	fi

uninstall:
	rm -f $(BIN_DIR)/create-shortcut.sh
	rm -f "$(NAUTILUS_SCRIPTS_DIR)/Создать ярлык"
	rm -f $(KDE_SERVICES_DIR)/create-shortcut.desktop
	@if [ -n "$$(pgrep -x gnome-shell)" ]; then \
		pkill -x nautilus || true; \
	elif [ -n "$$(pgrep -x plasmashell)" ]; then \
		kbuildsycoca6 || true; \
	fi
	echo "Uninstallation complete"
