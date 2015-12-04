require recipes-bsp/u-boot/u-boot.inc

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://README;beginline=1;endline=22;md5=2687c5ebfd9cb284491c3204b726ea29"

PR = "r0"
PV = "v2014.01+git${SRCPV}"

# This revision corresponds to the tag "v2014.01"
# We use the revision in order to avoid having to fetch it from the repo during parse
SRCREV = "b44bd2c73c4cfb6e3b9e7f8cf987e8e39aa74a0b"

SRC_URI = "git://git.denx.de/u-boot.git;branch=master;protocol=git \
	   file://0001-EXT4-Fix-number-base-handling-of-ext4write-command.patch \
	  "

# Adjust environment and MTD layout on M28EVK
SRC_URI_append_m28evk = " \
			file://0001-ARM-m28evk-add-needed-commands-and-options.patch \
			file://0002-ARM-m28evk-Adjust-mtdparts.patch \
			file://0003-ARM-m28evk-Update-default-environment.patch \
			"

# Adjust environment and MTD layout on M53EVK
SRC_URI_append_m53evk = " \
			file://0001-ARM-m53evk-add-needed-commands-and-options.patch \
			file://0002-ARM-m53evk-Adjust-mtdparts-settings.patch \
			file://0003-ARM-m53evk-Update-default-environment.patch \
			file://0004-common-Add-get_effective_memsize-to-memsize.c.patch \
			file://0005-arm-mx5-Fix-memory-slowness-on-M53EVK.patch \
			file://0006-arm-mx5-Avoid-hardcoding-memory-sizes-on-M53EVK.patch \
			"

# Build u-boot-with-nand-spl.imx for the M53EVK so we can place it in the image
do_compile_append_m53evk () {
	oe_runmake u-boot-with-nand-spl.imx
}
do_install_append_m53evk () {
        install ${S}/u-boot-with-nand-spl.imx \
		${D}/boot/u-boot-with-nand-spl-${MACHINE}-${PV}-${PR}.imx
        ln -sf u-boot-with-nand-spl-${MACHINE}-${PV}-${PR}.imx \
		${D}/boot/u-boot-with-nand-spl.imx
}
do_deploy_append_m53evk () {
        install ${S}/u-boot-with-nand-spl.imx \
		${DEPLOYDIR}/u-boot-with-nand-spl-${MACHINE}-${PV}-${PR}.imx
	rm -f u-boot-with-nand-spl.imx u-boot-with-nand-spl-${MACHINE}.imx
        ln -sf u-boot-with-nand-spl-${MACHINE}-${PV}-${PR}.imx \
		${DEPLOYDIR}/u-boot-with-nand-spl.imx
        ln -sf u-boot-with-nand-spl-${MACHINE}-${PV}-${PR}.imx \
		${DEPLOYDIR}/u-boot-with-nand-spl-${MACHINE}.imx
}

S = "${WORKDIR}/git"

FILESDIR = "${@os.path.dirname(d.getVar('FILE',1))}/u-boot-git/${MACHINE}"

PACKAGE_ARCH = "${MACHINE_ARCH}"

UBOOT_SRC_PATH = "/usr/src/u-boot"

FILES_${PN}-dev = "${UBOOT_SRC_PATH}"

do_install_append () {

    ubootsrcdir=${D}${UBOOT_SRC_PATH}

    install -d $ubootsrcdir

    #
    # Copy the entire source tree. In case an external build directory is
    # used, copy the build directory over first, then copy over the source
    # dir. This ensures the original Makefiles are used and not the
    # redirecting Makefiles in the build directory.

    cp -fR * $ubootsrcdir
    if [ "${S}" != "${B}" ]; then
        cp -fR ${S}/* $ubootsrcdir
    fi
    oe_runmake -C $ubootsrcdir distclean

}
