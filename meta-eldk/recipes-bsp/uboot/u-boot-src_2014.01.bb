LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://README;beginline=1;endline=22;md5=2687c5ebfd9cb284491c3204b726ea29"

PR = "r0"
PV = "v2014.01+git${SRCPV}"

BBCLASSEXTEND = "nativesdk"

# This revision corresponds to the tag "v2014.01"
# We use the revision in order to avoid having to fetch it from the repo during parse
SRCREV = "b44bd2c73c4cfb6e3b9e7f8cf987e8e39aa74a0b"

SRC_URI = "git://git.denx.de/u-boot.git;branch=master;protocol=git"

S = "${WORKDIR}/git"

FILESDIR = "${@os.path.dirname(d.getVar('FILE',1))}/u-boot-git/${MACHINE}"

PACKAGE_ARCH = "${MACHINE_ARCH}"

UBOOT_SRC_PATH = "${prefix}/src/u-boot"

FILES_${PN} = "${UBOOT_SRC_PATH}"

do_configure() {
    # just skip it
    ubootsrcdir=${D}${UBOOT_SRC_PATH}
}

do_compile() {
    # just skip it
    ubootsrcdir=${D}${UBOOT_SRC_PATH}
}

do_install () {
    ubootsrcdir=${D}${UBOOT_SRC_PATH}
    install -d $ubootsrcdir
    cp -fR * $ubootsrcdir
    if [ "${S}" != "${B}" ]; then
        cp -fR ${S}/* $ubootsrcdir
    fi
}
