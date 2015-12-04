DEFAULTTUNE ?= "ppc440e"

require conf/machine/include/powerpc/arch-powerpc.inc

TUNEVALID[ppc440e] = "Enable ppc440e specific processor optimizations"
TUNE_CCARGS += "${@bb.utils.contains("TUNE_FEATURES", "ppc440e", "-mcpu=440fp -mhard-float", "", d)}"
TUNE_PKGARCH_tune-ppc440e = "ppc440e"

AVAILTUNES += "ppc440e"
TUNE_FEATURES_tune-ppc440e = "m32 ppc440e"
PACKAGE_EXTRA_ARCHS_tune-ppc440e = "ppc440e"
