DESCRIPTION = "Create or check cramfs image"
SECTION = "base"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=9579385572eb40eded61dcb07e0038a4"

DEPENDS += "zlib"

SRCREV = "514ad72287e6654c51b8caaace0d50411e49ece5"

PR = "r0"

SRC_URI = "git://git.denx.de/cramfs.git;protocol=git"

S = "${WORKDIR}/git"

do_compile() {
	cd ${S}/scripts/cramfs
	${CC} -I../../include ${CFLAGS} -o mkcramfs mkcramfs.c -lz
	${CC} -I../../include ${CFLAGS} -o cramfsck cramfsck.c -lz
}

do_install() {
        install -d ${D}${sbindir}
        install -m 0755 ${S}/scripts/cramfs/mkcramfs ${D}${sbindir}
        install -m 0755 ${S}/scripts/cramfs/cramfsck ${D}${sbindir}
}

BBCLASSEXTEND += "native nativesdk"
