require linux.inc

# Mark archs/machines that this kernel supports
DEFAULT_PREFERENCE = "-1"
DEFAULT_PREFERENCE_generic-armv4t = "1"
DEFAULT_PREFERENCE_generic-armv5te = "1"
DEFAULT_PREFERENCE_generic-armv6 = "1"
DEFAULT_PREFERENCE_generic-armv7a = "1"
DEFAULT_PREFERENCE_generic-armv7a-hf = "1"
DEFAULT_PREFERENCE_generic-mips = "1"
DEFAULT_PREFERENCE_generic-powerpc = "1"
DEFAULT_PREFERENCE_generic-powerpc-softfloat = "1"
DEFAULT_PREFERENCE_generic-powerpc-4xx = "1"
DEFAULT_PREFERENCE_generic-powerpc-4xx-softfloat = "1"
DEFAULT_PREFERENCE_generic-powerpc-e500v2 = "1"

PR = "r25"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;protocol=git \
	   file://0001-mtd-mxc_nand-Make-use-of-supplied-pinctrl-data.patch \
	   file://0002-ARM-mx5-Add-AUDMUX4-pinctrl-data.patch \
	   file://0003-ARM-mx5-Add-CAN1-pinctrl-data.patch \
	   file://0004-ARM-mx5-Add-I2C1-pinctrl-data.patch \
	   file://0005-ARM-mx5-Add-I2C2-pinctrl-data.patch \
	   file://0006-ARM-mx5-Add-NAND-pinctrl-data.patch \
	   file://0007-ARM-mx5-Add-LCD-IPU-pinctrl-data.patch \
	   file://0008-ARM-mx5-Add-PWM1-pinctrl-data.patch \
	   file://0009-video-display_timing-make-parameter-const.patch \
	   file://0010-video-IPU-KMS-RGB565-to-BGR565-ordering-hack.patch \
	   file://0011-video-Avoid-IPU-CRTC-kernel-crash.patch \
	   file://0012-mfd-stmpe-Pull-IRQ-GPIO-number-from-DT-during-DT-bas.patch \
	   file://0013-input-stmpe-Fix-the-touchscreen-interrupt-handling.patch \
	   file://0014-ARM-mx5-Add-MX53-AHCI-bindings.patch \
	   file://0015-ARM-mx5-Add-MX53-AHCI-clock.patch \
	   file://0016-ARM-mx5-Add-MX53-AHCI-specifics.patch \
	   file://0017-ARM-mx5-Add-support-for-DENX-M53EVK.patch \
	   file://0018-ARM-mx5-Fix-audio-on-M53EVK.patch \
	   file://0019-ASoC-sgtl5000-Fix-VAG_POWER-enabling-disabling-order.patch \
	   file://0020-imx-drm-imx-drm-core-Fix-circular-locking-dependency.patch \
	   file://0021-drm-Add-LCD-display-clock-polarity-flags.patch \
	   file://0022-imx-drm-ipuv3-crtc-Make-DISP_CLK-polarity-configurab.patch \
	   file://0023-ARM-dts-imx53-Switch-DISP_CLK-polarity-on-M53EVK.patch \
	   file://0024-ARM-dts-mxs-Fix-the-RTC-compatible-prop-on-M28EVK.patch \
	   file://0025-ARM-dts-imx-Add-alias-for-ethernet-controller.patch \
	   file://defconfig"

LINUX_VERSION ?= "3.10.28"

# tag: v3.10.28 (linux-3.10.y) 020abbc91120ddf052e2c303a8c598c3be4dc459
SRCREV="020abbc91120ddf052e2c303a8c598c3be4dc459"

PV = "${LINUX_VERSION}+git${SRCPV}"

S = "${WORKDIR}/git"

COMPATIBLE_MACHINE = "generic-armv4t|generic-armv5te|generic-armv6|generic-armv7a|generic-armv7a-hf|generic-mips|generic-powerpc|generic-powerpc-softfloat|generic-powerpc-4xx|generic-powerpc-4xx-softfloat|generic-powerpc-e500v2|m28evk|m53evk"

# M53EVK specific
# We need SDMA-firmware for MX53
DEPENDS_append_m53evk = " sdma-firmware-native "
do_configure_prepend_m53evk() {
	# We cannot specify CONFIG_EXTRA_FIRMWARE on the kernel build command
	# line, since if we do that instead, we will get an error as such:
	#
	# | make[1]: *** No rule to make target
	# `include/config/extra/firmware/dir.h', needed by
	# `firmware/imx/sdma/sdma-imx53.bin.gen.S'.  Stop.
	# | make: *** [firmware] Error 2
	#
	# This is probably a bug in the kernel build architecture, but as of
	# writing this text, I did not investigate this too deeply. As a
	# workaround, patch the firmware filename into the kernel config.
	echo 'CONFIG_EXTRA_FIRMWARE="imx/sdma/sdma-imx53.bin"' >> ${WORKDIR}/defconfig
	cp -arv ${STAGING_DIR_NATIVE}/lib/firmware/imx ${S}/firmware/ || \
		die "no sdma-firmware found"
}
