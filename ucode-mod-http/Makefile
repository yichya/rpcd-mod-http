# SPDX-License-Identifier: MIT

include $(TOPDIR)/rules.mk

PKG_NAME:=ucode-mod-http
PKG_VERSION:=0.0.1
PKG_RELEASE:=1
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/ucode-mod-http
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=ucode-mod-http
	DEPENDS:=+ucode-mod-ctypes +ucode-mod-struct +ucode-mod-resolv
	MAINTAINER:=yichya <mail@yichya.dev>
endef

define Package/ucode-mod-http/description
	Invoke HTTP requests via ucode
endef

define Build/Compile
endef

define Package/ucode-mod-http/install
	$(INSTALL_DIR) $(1)/usr/share/ucode
	$(INSTALL_DATA) ./http.uc $(1)/usr/share/ucode/http.uc
endef

$(eval $(call BuildPackage,ucode-mod-http))
