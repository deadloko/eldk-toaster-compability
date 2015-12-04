DEFAULTTUNE ?= "ppc405"

require conf/machine/include/powerpc/arch-powerpc.inc

TUNEVALID[ppc405] = "Enable ppc405 specific processor optimizations"
TUNE_CCARGS += "${@bb.utils.contains("TUNE_FEATURES", "ppc405", "-mcpu=405", "", d)}"
TUNE_PKGARCH_tune-ppc405 = "ppc405"

AVAILTUNES += "ppc405"
TUNE_FEATURES_tune-ppc405 = "m32 ppc405 fpu-soft"
PACKAGE_EXTRA_ARCHS_tune-ppc405 = "ppc405"
