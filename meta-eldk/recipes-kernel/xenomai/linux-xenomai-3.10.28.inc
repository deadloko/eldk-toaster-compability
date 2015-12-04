FILESEXTRAPATHS_prepend := "${THISDIR}/../linux/linux-eldk"

SRC_URI += "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;protocol=git;name=linux \
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
	   file://0001-ipipe-kernel-3.10.patch;patchdir=${WORKDIR}/xenomai-${XENOMAI_VER} \
	   file://defconfig"

LINUX_VERSION ?= "3.10.28"

# tag: v3.10.28 (linux-3.10.y) 020abbc91120ddf052e2c303a8c598c3be4dc459
SRCREV="020abbc91120ddf052e2c303a8c598c3be4dc459"

S = "${WORKDIR}/git"
