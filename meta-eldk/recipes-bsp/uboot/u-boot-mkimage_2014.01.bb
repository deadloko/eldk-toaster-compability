DESCRIPTION = "U-boot bootloader mkimage and mxsboot tool"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://README;beginline=1;endline=22;md5=2687c5ebfd9cb284491c3204b726ea29"
SECTION = "bootloader"

PR = "r1"
PV = "v2014.01+git${SRCPV}"

# We must depend on OpenSSL in case we build mkimage with MXS image or
# signed image support. As we do build at least MXS image support, make
# sure we depend on OpenSSL.
DEPENDS += "openssl"

# This revision corresponds to the tag "v2014.01"
# We use the revision in order to avoid having to fetch it from the repo during parse
SRCREV = "b44bd2c73c4cfb6e3b9e7f8cf987e8e39aa74a0b"

SRC_URI = "git://git.denx.de/u-boot.git;branch=master;protocol=git"

S = "${WORKDIR}/git"

BBCLASSEXTEND = "native nativesdk"

EXTRA_OEMAKE = 'CROSS_COMPILE="${TARGET_PREFIX}" HOSTCC="${CC}" HOSTLD="${LD}" HOSTLDFLAGS="${LDFLAGS}" HOSTSTRIP=true'

# Make sure the MXS-specific tools will build. This encomprises both
# tools/mxsboot as well as tools/mkimage with MXS image support.
EXTRA_OEMAKE += " CONFIG_MX28=y"

do_compile () {
  oe_runmake tools
}

do_install () {
  install -d ${D}${bindir}
  install -m 0755 tools/mkimage ${D}${bindir}/mkimage
  install -m 0755 tools/mxsboot ${D}${bindir}/mxsboot
}
