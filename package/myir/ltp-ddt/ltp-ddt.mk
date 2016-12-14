################################################################################
#
# ltp-ddt
#
################################################################################

LTP_DDT_VERSION = master
LTP_DDT_SITE = http://192.168.30.2:3000/sunnyguo-myir/myir-ltp-ddt.git
LTP_DDT_SITE_METHOD = git
LTP_DDT_LICENSE = GPLv2, GPLv2+
LTP_DDT_LICENSE_FILES = COPYING
LTP_DDT_CONF_OPTS += \
	--with-power-management-testsuite \
	--with-realtime-testsuite
LTP_DDT_AUTORECONF = YES

ifeq ($(BR2_LINUX_KERNEL),y)
LTP_DDT_DEPENDENCIES += linux
LTP_DDT_MAKE_ENV += $(LINUX_MAKE_FLAGS) SKIP_IDCHECK=1 KERNEL_USR_INC=$(STAGING_DIR)/usr/include
LTP_DDT_CONF_OPTS += --with-linux-dir=$(LINUX_DIR)
else
LTP_DDT_CONF_OPTS += --without-modules
endif

# We change the prefix to a custom one, otherwise we get scripts and
# directories directly in /usr, such as /usr/runalltests.sh
LTP_DDT_CONF_OPTS += --prefix=/usr/lib/ltp-ddt

# Needs libcap with file attrs which needs attr, so both required
ifeq ($(BR2_PACKAGE_LIBCAP)$(BR2_PACKAGE_ATTR),yy)
LTP_DDT_DEPENDENCIES += libcap
else
LTP_DDT_CONF_ENV += ac_cv_lib_cap_cap_compare=no
endif

# ltp-DDT uses <fts.h>, which isn't compatible with largefile
# support.
LTP_DDT_CFLAGS = $(filter-out -D_FILE_OFFSET_BITS=64,$(TARGET_CFLAGS))
LTP_DDT_CPPFLAGS = $(filter-out -D_FILE_OFFSET_BITS=64,$(TARGET_CPPFLAGS))
LTP_DDT_LIBS =

ifeq ($(BR2_PACKAGE_LIBTIRPC),y)
LTP_DDT_DEPENDENCIES += libtirpc host-pkgconf
LTP_DDT_CFLAGS += "`$(PKG_CONFIG_HOST_BINARY) --cflags libtirpc`"
LTP_DDT_LIBS += "`$(PKG_CONFIG_HOST_BINARY) --libs libtirpc`"
endif

ifeq ($(BR2_PACKAGE_ALSA_LIB),y)
LTP_DDT_DEPENDENCIES += alsa-lib
endif


LTP_DDT_CONF_ENV += \
	CFLAGS="$(LTP_DDT_CFLAGS)" \
	CPPFLAGS="$(LTP_DDT_CPPFLAGS)" \
	LIBS="$(LTP_DDT_LIBS)" \
	SYSROOT="$(STAGING_DIR)"

# Requires uClibc fts and bessel support, normally not enabled
ifeq ($(BR2_TOOLCHAIN_USES_UCLIBC),y)
define LTP_DDT_REMOVE_UNSUPPORTED
	rm -rf $(@D)/testcases/kernel/controllers/cpuset/
	rm -rf $(@D)/testcases/misc/math/float/bessel/
	rm -f $(@D)/testcases/misc/math/float/float_bessel.c
endef
LTP_DDT_POST_PATCH_HOOKS += LTP_DDT_REMOVE_UNSUPPORTED
endif

LTP_DDT_POST_PATCH_HOOKS += LTP_DDT_MAKE_AUTOTOOLS

define LTP_DDT_MAKE_AUTOTOOLS
	cd $(@D) && make autotools
endef


$(eval $(autotools-package))
