################################################################################
#
# python-pyconnman
#
################################################################################

PYTHON_PYCONNMAN_VERSION = 0.1.0
PYTHON_PYCONNMAN_SOURCE = pyconnman-$(PYTHON_PYCONNMAN_VERSION).tar.gz
PYTHON_PYCONNMAN_SITE = http://pypi.python.org/packages/source/p/pyconnman
PYTHON_PYCONNMAN_LICENSE = Apache
PYTHON_PYCONNMAN_SETUP_TYPE = distutils

$(eval $(python-package))

