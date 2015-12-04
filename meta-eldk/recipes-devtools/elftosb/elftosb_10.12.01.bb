DESCRIPTION = "To make a MXS based board bootable, some tools are necessary. The first one is the \"elftosb\" tool distributed by Freescale Semiconductor. The other on is the \"mxsboot\" tool found in U-Boot source tree."
SUMMARY = ""
HOMEPAGE = "I don't have no homepage"
BUGTRACKER = ""

## something related to the bootloader
SECTION = "bootloader"

## find the "COPYING" file and run md5sum on it, to obtain the checksum
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=172ede34353056ebec7a597d8459f029"

DISTRO_PN_ALIAS = ""

PR = "r0"

SRC_URI = "ftp://ftp.denx.de/pub/tools/elftosb-${PV}.tar.gz;name=elftosb \
	    file://don-t-use-full-path-for-headers.patch"
SRC_URI[elftosb.md5sum] = "e8005d606c1e0bb3507c82f6eceb3056"
SRC_URI[elftosb.sha256sum] = "77bb6981620f7575b87d136d94c7daa88dd09195959cc75fc18b138369ecd42b"

## for the installation, where to fetch the binary
S = "${WORKDIR}/elftosb-${PV}"

## set make arguments via EXTRA_ flags!
EXTRA_OEMAKE := 'LIBS="-lstdc++ -lm" elftosb'

do_install () {
    ## make directory
    install -d ${D}${bindir}

    ## copy file into directory, and set exec permissions
    install -m 0755 ${S}/bld/linux/elftosb ${D}${bindir} || die "installation failed"
}

## this is part of the native sdk
BBCLASSEXTEND = " native nativesdk "
