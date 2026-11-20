################################################################################
#
# rtl88x2cu (OpenHD fork - produces 8812cu_ohd.ko with monitor mode support)
#
################################################################################

RTL88X2CU_VERSION = 73f36ba
RTL88X2CU_SITE = $(call github,OpenHD,rtl88x2cu,$(RTL88X2CU_VERSION))
RTL88X2CU_LICENSE = GPL-3.0
RTL88X2CU_DEPENDENCIES = linux

RTL88X2CU_MODULE_MAKE_OPTS = \
	CONFIG_RTL8822CU=m \
	CONFIG_PLATFORM_I386_PC=y \
	ARCH=arm \
	KSRC=$(LINUX_DIR) \
	CROSS_COMPILE=$(TARGET_CROSS)

define RTL88X2CU_BUILD_CMDS
	$(MAKE) -C $(@D) $(RTL88X2CU_MODULE_MAKE_OPTS)
endef

define RTL88X2CU_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/8812cu.ko \
		$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/8812cu.ko
	# Also install the ohd variant if present (monitor mode support)
	-$(INSTALL) -D -m 0644 $(@D)/8812cu_ohd.ko \
		$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/extra/8812cu_ohd.ko
endef

$(eval $(generic-package))