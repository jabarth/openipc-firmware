################################################################################
#
# rtl88x2cu
#
################################################################################

RTL88X2CU_VERSION = 132c1e32b93c0678c01e631bfb9d014a575eeb13
RTL88X2CU_SITE = $(call github,libc0607,rtl88x2cu-20230728,$(RTL88X2CU_VERSION))
RTL88X2CU_LICENSE = GPL-2.0

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
endef

$(eval $(generic-package))
