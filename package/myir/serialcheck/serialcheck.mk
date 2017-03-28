################################################################################
#
# serialcheck
#
################################################################################

SERIALCHECK_VERSION = master
SERIALCHECK_SITE = git://git.breakpoint.cc/bigeasy/serialcheck.git
SERIALCHECK_SITE_METHOD = git

SERIALCHECK_CFLAGS += -I $(@D) -I $(STAGING_DIR)/usr/include

SERIALCHECK_BUILDOPTS = $(TARGET_CONFIGURE_OPTS) \
		CC="$(TARGET_CC)" \
        LDFLAGS="$(TARGET_LDFLAGS) $(SERIALCHECK_LDLIBS)" \
        CFLAGS="$(TARGET_CFLAGS) $(SERIALCHECK_CFLAGS)" 

SERIALCHECK_MAKE_ENV = \
	$(TARGET_MAKE_ENV) \
	PREFIX=$(TARGET_DIR)/usr 

define SERIALCHECK_BUILD_CMDS
	$(SERIALCHECK_MAKE_ENV) \
	$(MAKE) $(SERIALCHECK_BUILDOPTS) -C $(@D) CROSS_ROOT=$(STAGING_DIR)
endef

define SERIALCHECK_INSTALL_TARGET_CMDS
	$(INSTALL) -m 755 -D $(@D)/serialcheck $(TARGET_DIR)/usr/bin/serialcheck;
endef

$(eval $(generic-package))



