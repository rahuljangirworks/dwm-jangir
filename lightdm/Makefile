.PHONY: install print-config rpm

LIGHTDM_DIR = $(DESTDIR)/etc/lightdm
LIGHTDM_CONF = $(LIGHTDM_DIR)/lightdm.conf
PIXMAPS_DIR = $(DESTDIR)/usr/share/pixmaps
GREETER_DIR = $(DESTDIR)/usr/share/xgreeters
GREETER_LIBEXEC_DIR = $(DESTDIR)/usr/libexec
GREETER_ASSET_DIR = $(DESTDIR)/usr/share/dwm-jangir/lightdm-backgrounds
GREETER_UI_ASSET_DIR = $(DESTDIR)/usr/share/dwm-jangir/lightdm-assets
GREETER_THEME_DIR = $(DESTDIR)/usr/share/themes/dwm-jangir-dark/gtk-3.0
LIGHTDM_SEAT_SECTION ?= Seat:*
LIGHTDM_GREETER_SESSION ?= dwm-jangir-slick-greeter
LIGHTDM_GREETER_SESSION ?= slick-greeter
LIGHTDM_USER_SESSION ?= dwm-jangir
LIGHTDM_SESSION_WRAPPER ?=
LIGHTDM_LOGIND_CHECK ?= true

print-config:
	@if [ "$(LIGHTDM_LOGIND_CHECK)" = true ]; then \
		printf '%s\n' '[LightDM]'; \
		printf '%s\n' 'logind-check-graphical=true'; \
		printf '\n'; \
	fi; \
	printf '[%s]\n' "$(LIGHTDM_SEAT_SECTION)"; \
	printf 'greeter-session=%s\n' "$(LIGHTDM_GREETER_SESSION)"; \
	printf 'user-session=%s\n' "$(LIGHTDM_USER_SESSION)"; \
	if [ -n "$(LIGHTDM_SESSION_WRAPPER)" ]; then \
		printf 'session-wrapper=%s\n' "$(LIGHTDM_SESSION_WRAPPER)"; \
	fi

install:
	tmp=$$(mktemp); \
	trap 'rm -f "$$tmp"' EXIT; \
	$(MAKE) --no-print-directory print-config >"$$tmp"; \
	if [ -f $(LIGHTDM_CONF) ] && ! cmp -s "$$tmp" $(LIGHTDM_CONF); then \
		cp -a $(LIGHTDM_CONF) $(LIGHTDM_CONF).dwm-jangir.$$(date +%Y%m%d%H%M%S).bak; \
	fi; \
	install -Dm644 "$$tmp"                           $(LIGHTDM_CONF)
	install -Dm644 slick-greeter.conf                $(LIGHTDM_DIR)/slick-greeter.conf
	install -Dm644 wallpaper.jpg                     $(PIXMAPS_DIR)/dwm-jangir.jpg
	install -Dm644 ../dwm-jangir.png                   $(PIXMAPS_DIR)/dwm-jangir-logo.png
	install -Dm755 dwm-jangir-slick-greeter          $(GREETER_LIBEXEC_DIR)/dwm-jangir-slick-greeter
	install -Dm644 dwm-jangir-slick-greeter.desktop  $(GREETER_DIR)/dwm-jangir-slick-greeter.desktop
	install -Dm644 theme/dwm-jangir-dark/gtk-3.0/gtk.css $(GREETER_THEME_DIR)/gtk.css
	install -d                                      $(GREETER_ASSET_DIR)
	install -Dm644 wallpapers/*.webp                 $(GREETER_ASSET_DIR)/
	install -Dm644 wallpapers/SOURCES.md             $(GREETER_ASSET_DIR)/SOURCES.md
	install -Dm644 assets/dwm.svg                     $(GREETER_UI_ASSET_DIR)/dwm.svg
	install -Dm644 assets/kde.svg                     $(GREETER_UI_ASSET_DIR)/kde.svg
	install -Dm644 assets/gnome.svg                   $(GREETER_UI_ASSET_DIR)/gnome.svg

rpm:
	./rpm/build-dwm-jangir-slick-greeter-rpm.sh
