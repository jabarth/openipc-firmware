################################################################################
#
# waybeam_venc
#
################################################################################

WAYBEAM_VENC_VERSION = 82f72acd812677996dd5ff545420beb68a05377c
WAYBEAM_VENC_SITE = https://github.com/OpenIPC/waybeam_venc.git
WAYBEAM_VENC_SITE_METHOD = git
WAYBEAM_VENC_LICENSE = GPL-2.0

define WAYBEAM_VENC_BUILD_CMDS
	$(MAKE) -C $(@D) CC="$(TARGET_CC)" SOC_BUILD=star6e
endef

define WAYBEAM_VENC_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/waybeam_venc $(TARGET_DIR)/usr/bin/waybeam_venc
	$(INSTALL) -D -m 0755 $(WAYBEAM_VENC_PKGDIR)/S95waybeam $(TARGET_DIR)/etc/init.d/S95waybeam
	$(INSTALL) -D -m 0644 $(WAYBEAM_VENC_PKGDIR)/waybeam.json $(TARGET_DIR)/etc/waybeam.json
endef

$(eval $(generic-package))
