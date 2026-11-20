################################################################################
#
# rtl88x2cu (OpenHD fork - produces 88x2cu_ohd.ko with monitor mode support)
#
################################################################################

RTL88X2CU_VERSION = 73f36ba
RTL88X2CU_SITE = $(call github,OpenHD,rtl88x2cu,$(RTL88X2CU_VERSION))
RTL88X2CU_LICENSE = GPL-3.0
RTL88X2CU_DEPENDENCIES = linux $(if $(BR2_PACKAGE_CFG80211),cfg80211)

RTL88X2CU_MODULE_MAKE_OPTS = 	CONFIG_RTL8822CU=m 	CONFIG_PLATFORM_I386_PC=y 	ARCH=arm 	KSRC=$(LINUX_DIR) 	CROSS_COMPILE=$(TARGET_CROSS)

define RTL88X2CU_BUILD_CMDS
	$(MAKE) -C $(@D) $(RTL88X2CU_MODULE_MAKE_OPTS)
endef

define RTL88X2CU_INSTALL_TARGET_CMDS
	# OpenHD fork with CONFIG_RTL8822CU produces 88x2cu_ohd.ko
	$(INSTALL) -D -m 0644 $(@D)/88x2cu_ohd.ko 		$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/88x2cu_ohd.ko
	# Symlinks so both on-disk names used by init scripts resolve to the module
	ln -sf 88x2cu_ohd.ko $(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/8812cu_ohd.ko
	ln -sf 88x2cu_ohd.ko $(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/8812cu.ko
	# /etc/modules: cfg80211 must load before 8812cu_ohd (insmod needs wiphy_register)
	$(INSTALL) -m 644 -D $(RTL88X2CU_PKGDIR)/files/etc/modules $(TARGET_DIR)/etc/modules
endef

$(eval $(generic-package))