################################################################################
#
# pcba_test
#
################################################################################

PCBA_TEST_VERSION = feature_pcba_test_myd_c437x_idk
PCBA_TEST_SITE = http://192.168.30.2:3000/sunnyguo-myir/myir-pcba-test.git
PCBA_TEST_SITE_METHOD = git
PCBA_TEST_LICENSE = Creative Commons CC0 1.0 Universal
PCBA_LICENSE_FILES = LICENSE

ifeq ($(BR2_PACKAGE_ALSA_LIB),y)
PCBA_TEST_DEPENDENCIES = alsa-lib
PCBA_TEST_LDLIBS += -lpthread -lasound -L $(STAGING_DIR)/usr/lib
endif

PCBA_TEST_CFLAGS += -I $(@D) -I $(STAGING_DIR)/usr/include

PCBA_TEST_BUILDOPTS = $(TARGET_CONFIGURE_OPTS) \
		CC="$(TARGET_CC)" \
        LDFLAGS="$(TARGET_LDFLAGS) $(PCBA_TEST_LDLIBS)" \
        CFLAGS="$(TARGET_CFLAGS) $(PCBA_TEST_CFLAGS)" 

PCBA_TEST_MAKE_ENV = \
	$(TARGET_MAKE_ENV) \
	PREFIX=$(TARGET_DIR)/usr \
	OPTION=$(BR2_PACKAGE_MYIR_PLATFORM) 

define PCBA_TEST_BUILD_CMDS
	$(PCBA_TEST_MAKE_ENV) \
	$(MAKE) $(PCBA_TEST_BUILDOPTS) -C $(@D) CROSS_ROOT=$(STAGING_DIR)
endef

define PCBA_TEST_INSTALL_TARGET_CMDS
	$(PCBA_TEST_MAKE_ENV) $(MAKE) -C $(@D) install
endef

$(eval $(generic-package))



