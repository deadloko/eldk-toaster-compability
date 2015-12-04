include recipes-core/meta/meta-toolchain-gmae.bb

TOOLCHAIN_TARGET_GMAETASK += "kernel-ipipe-dev xenomai-dev"
TOOLCHAIN_OUTPUTNAME = "${SDK_NAME}-toolchain-xenomai-gmae-${DISTRO_VERSION}"
PROVIDES = "meta-toolchain-xenomai-sdk"
