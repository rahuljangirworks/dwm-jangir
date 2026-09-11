.PHONY: install print-config

LIGHTDM_DIR = $(DESTDIR)/etc/lightdm
LIGHTDM_CONF = $(LIGHTDM_DIR)/lightdm.conf
PIXMAPS_DIR = $(DESTDIR)/usr/share/pixmaps
LIGHTDM_SEAT_SECTION ?= Seat:*
LIGHTDM_GREETER_SESSION ?=
LIGHTDM_USER_SESSION ?= dwm-jangir
LIGHTDM_SESSION_WRAPPER ?=
LIGHTDM_LOGIND_CHECK ?= true
LIGHTDM_THEME ?= stock

SOLAR_LIBEXEC_DIR = $(DESTDIR)/usr/libexec
SOLAR_XGREETERS_DIR = $(DESTDIR)/usr/share/xgreeters
SOLAR_ASSETS_DIR = $(DESTDIR)/usr/share/dwm-jangir/lightdm-assets
SOLAR_THEME_DIR = $(DESTDIR)/usr/share/themes/dwm-jangir-dark

ifeq ($(LIGHTDM_THEME),stock)
GREETER_CONFIG = slick-greeter.conf
ifeq ($(strip $(LIGHTDM_GREETER_SESSION)),)
LIGHTDM_GREETER_SESSION = slick-greeter
endif
else ifeq ($(LIGHTDM_THEME),solar)
GREETER_CONFIG = solar-slick-greeter.conf
ifeq ($(strip $(LIGHTDM_GREETER_SESSION)),)
LIGHTDM_GREETER_SESSION = dwm-jangir-slick-greeter
endif
else
$(error LIGHTDM_THEME must be either stock or solar (got '$(LIGHTDM_THEME)'))
endif

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
	install -Dm644 $(GREETER_CONFIG)                 $(LIGHTDM_DIR)/slick-greeter.conf
	install -Dm644 wallpaper.jpg                     $(PIXMAPS_DIR)/dwm-jangir.jpg
	install -Dm644 ../dwm-jangir.png                 $(PIXMAPS_DIR)/dwm-jangir-logo.png
ifeq ($(LIGHTDM_THEME),solar)
	install -Dm755 dwm-jangir-slick-greeter          $(SOLAR_LIBEXEC_DIR)/dwm-jangir-slick-greeter
	install -Dm644 dwm-jangir-slick-greeter.desktop  $(SOLAR_XGREETERS_DIR)/dwm-jangir-slick-greeter.desktop
	install -Dm644 assets/dwm.svg                    $(SOLAR_ASSETS_DIR)/dwm.svg
	install -Dm644 assets/gnome.svg                  $(SOLAR_ASSETS_DIR)/gnome.svg
	install -Dm644 assets/kde.svg                    $(SOLAR_ASSETS_DIR)/kde.svg
	install -Dm644 theme/dwm-jangir-dark/gtk-3.0/gtk.css $(SOLAR_THEME_DIR)/gtk-3.0/gtk.css
endif
