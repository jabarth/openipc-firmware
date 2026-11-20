################################################################################
#
# rtl88x2cu (OpenHD fork - produces 88x2cu_ohd.ko with monitor mode support)
#
################################################################################

RTL88X2CU_VERSION = 73f36ba
RTL88X2CU_SITE = $(call github,OpenHD,rtl88x2cu,$(RTL88X2CU_VERSION))
RTL88X2CU_LICENSE = GPL-3.0
RTL88X2CU_DEPENDENCIES = linux

RTL88X2CU_MODULE_MAKE_OPTS = 	CONFIG_RTL8822CU=m 	CONFIG_PLATFORM_I386_PC=y 	ARCH=arm 	KSRC=$(LINUX_DIR) 	CROSS_COMPILE=$(TARGET_CROSS)

define RTL88X2CU_BUILD_CMDS
	$(MAKE) -C $(@D) $(RTL88X2CU_MODULE_MAKE_OPTS)
endef

define RTL88X2CU_INSTALL_TARGET_CMDS
	# OpenHD fork with CONFIG_RTL8822CU produces 88x2cu_ohd.ko
	$(INSTALL) -D -m 0644 $(@D)/88x2cu_ohd.ko 		$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/88x2cu_ohd.ko
	# Also create symlink as 8812cu.ko for compatibility
	ln -sf 88x2cu_ohd.ko $(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/8812cu.ko
endef

$(eval $(generic-package))