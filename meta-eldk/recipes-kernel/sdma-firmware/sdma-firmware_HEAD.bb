DESCRIPTION = "external sdma-firmware blob"
SECTION = "base"
HOMEPAGE = "http://git.pengutronix.de/git/imx/sdma-firmware.git/"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://sdma-gen-image.c;beginline=1;endline=19;md5=8db9f935666ba755af54af9d8611b857"
PR = "r10"

inherit autotools

SRC_URI = "git://git.pengutronix.de/git/imx/sdma-firmware.git/"

## curr HEAD: "4aede1eb121e8199d33fe6697f4c91405086000a"
SRCREV = "4aede1eb121e8199d33fe6697f4c91405086000a"

S = "${WORKDIR}/git"

do_install(){
    install -d ${base_libdir}/firmware/imx/sdma || die "dirpath not possible"
    install -m 755 sdma-imx53.bin ${base_libdir}/firmware/imx/sdma/sdma-imx53.bin || die "not possible to install sdma-imx53.bin under provided path"
}

BBCLASSEXTEND = "native nativesdk"
