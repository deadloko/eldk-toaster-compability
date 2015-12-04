IMAGE_FEATURES += "tools-debug tools-profile \
			tools-sdk dev-pkgs package-management splash \
			ssh-server-openssh"

CORE_IMAGE_EXTRA_INSTALL = "packagegroup-qte-toolchain-target qt4-embedded-tools \
			qt4-embedded-demos qt4-embedded-examples \
			qt4-embedded-plugin-mousedriver-tslib \
			qt4-embedded-plugin-kbddriver-linuxinput \
			tslib tslib-calibrate tslib-tests \
			packagegroup-base-nfs \
			xenomai kernel-ipipe-dev "

LICENSE = "MIT"

inherit core-image

PACKAGE_GROUP_tools-profile="packagegroup-core-tools-profile-ipipe"
