# needed just because its depends to oprofile - that kernel related
# need to check version of original oprofileui-git.bb at update time

require recipes-kernel/oprofile/oprofileui.inc

DEPENDS += "gtk+ libglade libxml2 avahi-ui gconf"

SRCREV = "f168b8bfdc63660033de1739c6ddad1abd97c379"
PV = "0.0+git${SRCPV}"

S = "${WORKDIR}/git"

SRC_URI = "git://git.yoctoproject.org/oprofileui"

EXTRA_OECONF += "--enable-client --disable-server"

PACKAGES =+ "oprofileui-viewer-ipipe"

FILES_oprofileui-viewer-ipipe = "${bindir}/oparchconv ${bindir}/oprofile-viewer ${datadir}/applications/ ${datadir}/oprofileui/ ${datadir}/icons"
RDEPENDS_oprofileui-viewer-ipipe = "oprofile-ipipe"

SSTATE_DUPWHITELIST = "oprofileui"


