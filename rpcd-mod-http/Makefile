# SPDX-License-Identifier: MIT

include $(TOPDIR)/rules.mk

PKG_NAME:=rpcd-mod-http
PKG_VERSION:=0.0.1
PKG_RELEASE:=1
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/rpcd-mod-http
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=rpcd-mod-http
	DEPENDS:=+ucode-mod-http
	MAINTAINER:=yichya <mail@yichya.dev>
endef

define Package/rpcd-mod-http/description
	Invoke HTTP requests via ubus
endef

define Build/Compile
endef

define Package/rpcd-mod-http/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/ucode
	$(INSTALL_DATA) ./http.uc $(1)/usr/share/rpcd/ucode/http.uc
endef

$(eval $(call BuildPackage,rpcd-mod-http))
