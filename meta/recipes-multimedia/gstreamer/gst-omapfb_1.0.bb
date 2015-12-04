DESCRIPTION = "GST output sink for Omapfb"
LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://LICENSE;md5=4fbd65380cdd255951079008b364516c"

inherit autotools

DEPENDS = "gstreamer virtual/kernel"

SRCREV = "41c0ef0d67dc9b718ab3a2aeecccc53b9ba8d783"

PV = "1.0+${PR}"

SRC_URI = "git://github.com/felipec/${PN}.git;protocol=git \
           file://gst-omapfb-cross-gcc-fix.patch \
	   file://0001-modify-to-use-on-AM3517-with-Qt-Embedded-OMAPFB-over.patch \
	   file://0002-gst-omapfb-modify-to-use-with-Qt-Mobility-extensions.patch"

S = "${WORKDIR}/git"

STAGING_KERNEL_DIR = "${STAGING_DIR}/${MACHINE}/kernel"

EXTRA_OEMAKE = " KERNEL=${STAGING_KERNEL_DIR}"
CFLAGS += "-I${S}"

TARGET_CC_ARCH += "${CFLAGS} ${LDFLAGS}"

do_configure_prepend() {
	install -d ${S}/linux
	cp ${STAGING_KERNEL_DIR}/include/linux/omapfb.h ${S}/linux || true
	    sed -e 's/__user//g' -i ${S}/linux/omapfb.h
}

do_install() {
	install -d ${D}${libdir}/gstreamer-0.10
	install -m 0755 libgstomapfb.so ${D}${libdir}/gstreamer-0.10
}

FILES_${PN} += "${libdir}/gstreamer-0.10/libgstomapfb.so"
FILES_${PN}-dbg += "${libdir}/gstreamer-0.10/.debug"
