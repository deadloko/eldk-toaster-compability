include recipes-qt/meta/meta-toolchain-qte.bb

TOOLCHAIN_TARGET_TASK += "kernel-ipipe-dev xenomai-dev"
TOOLCHAIN_OUTPUTNAME = "${SDK_NAME}-toolchain-xenomai-${QTNAME}-${DISTRO_VERSION}"
