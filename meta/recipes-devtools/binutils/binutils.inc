SUMMARY = "A GNU collection of binary utilities"
DESCRIPTION = "The GNU Binutils are a collection of binary tools. \
The main ones are ld (GNU Linker), and as (GNU Assembler). This \
package also includes addition tools such as addr2line (Converts \
addresses into filenames and line numbers), ar (utility for creating, \
modifying and extracting archives), nm (list symbols in object \
files), objcopy (copy and translate object files), objdump (Display \
object information), and other tools and related libraries."
HOMEPAGE = "http://www.gnu.org/software/binutils/"
BUGTRACKER = "http://sourceware.org/bugzilla/"
SECTION = "devel"
LICENSE = "GPLv3"

DEPENDS = "flex-native bison-native zlib-native gnu-config-native"

inherit autotools gettext multilib_header

PACKAGES += "${PN}-symlinks"

FILES_${PN} = " \
	${bindir}/${TARGET_PREFIX}* \
	${libdir}/lib*-*.so \
	${prefix}/${TARGET_SYS}/bin/*"

FILES_${PN}-dev = " \
	${includedir} \
	${libdir}/*.la \
	${libdir}/libbfd.so \
	${libdir}/libopcodes.so"

FILES_${PN}-symlinks = " \
	${bindir}/addr2line \
	${bindir}/as \
	${bindir}/c++filt \
	${bindir}/embedspu \
	${bindir}/gprof \
	${bindir}/ld \
	${bindir}/ld.bfd \
	${bindir}/ld.gold \
	${bindir}/nm \
	${bindir}/objcopy \
	${bindir}/objdump \
	${bindir}/ranlib \
	${bindir}/readelf \
	${bindir}/elfedit \
	${bindir}/size \
	${bindir}/strip \
	"

FILES_${PN}-dbg += "${prefix}/${TARGET_SYS}/bin/.debug"

B = "${S}/build.${HOST_SYS}.${TARGET_SYS}"

EXTRA_OECONF = "--program-prefix=${TARGET_PREFIX} \
                --disable-werror \
		--enable-plugins \
		${@base_contains('DISTRO_FEATURES', 'ld-is-gold', '--enable-gold=default --enable-threads', '', d)} \
                ${@base_contains('DISTRO_FEATURES', 'multiarch', '--enable-64-bit-bfd', '', d)}"

# This is necessary due to a bug in the binutils Makefiles
# EXTRA_OEMAKE = "configure-build-libiberty all"

export AR = "${HOST_PREFIX}ar"
export AS = "${HOST_PREFIX}as"
export LD = "${HOST_PREFIX}ld"
export NM = "${HOST_PREFIX}nm"
export RANLIB = "${HOST_PREFIX}ranlib"
export OBJCOPY = "${HOST_PREFIX}objcopy"
export OBJDUMP = "${HOST_PREFIX}objdump"

export AR_FOR_TARGET = "${TARGET_PREFIX}ar"
export AS_FOR_TARGET = "${TARGET_PREFIX}as"
export LD_FOR_TARGET = "${TARGET_PREFIX}ld"
export NM_FOR_TARGET = "${TARGET_PREFIX}nm"
export RANLIB_FOR_TARGET = "${TARGET_PREFIX}ranlib"

export CC_FOR_HOST = "${CCACHE}${HOST_PREFIX}gcc ${HOST_CC_ARCH}"
export CXX_FOR_HOST = "${CCACHE}${HOST_PREFIX}gcc ${HOST_CC_ARCH}"

# autotools.bbclass sets the _FOR_BUILD variables, but for some reason we need
# to unset LD_LIBRARY_PATH.
export CC_FOR_BUILD = "LD_LIBRARY_PATH= ${BUILD_CC}"

MULTIARCH := "${@bb.utils.contains("DISTRO_FEATURES", "multiarch", "yes", "no", d)}"
do_configure[vardeps] += "MULTIARCH"
do_configure () {
	(cd ${S}; gnu-configize) || die "Failed to run gnu-configize"
	oe_runconf
#
# must prime config.cache to ensure the build of libiberty
#
	mkdir -p ${B}/build-${BUILD_SYS}
	for i in ${CONFIG_SITE}; do
		cat $i >> ${B}/build-${BUILD_SYS}/config.cache || true
	done
}

do_install () {
	autotools_do_install

	# We don't really need these, so we'll remove them...
	rm -rf ${D}${libdir}/ldscripts

	# Fix the /usr/${TARGET_SYS}/bin/* links
	for l in ${D}${prefix}/${TARGET_SYS}/bin/*; do
		rm -f $l
		ln -sf `echo ${prefix}/${TARGET_SYS}/bin \
			| tr -s / \
			| sed -e 's,^/,,' -e 's,[^/]*,..,g'`${bindir}/${TARGET_PREFIX}`basename $l` $l
	done

	# Install the libiberty header
	install -d ${D}${includedir}
	install -m 644 ${S}/include/ansidecl.h ${D}${includedir}
	install -m 644 ${S}/include/libiberty.h ${D}${includedir}

	cd ${D}${bindir}

	# Symlinks for ease of running these on the native target
	for p in ${TARGET_PREFIX}* ; do
		ln -sf $p `echo $p | sed -e s,${TARGET_PREFIX},,`
	done

	rm -f ${D}${bindir}/ar ${D}${bindir}/strings

	oe_multilib_header bfd.h
}

inherit update-alternatives

ALTERNATIVE_PRIORITY = "100"

ALTERNATIVE_${PN}-symlinks = "ar strings"

ALTERNATIVE_LINK_NAME[ar] = "${bindir}/ar"
ALTERNATIVE_TARGET[ar] = "${bindir}/${TARGET_PREFIX}ar"

ALTERNATIVE_LINK_NAME[strings] = "${bindir}/strings"
ALTERNATIVE_TARGET[strings] = "${bindir}/${TARGET_PREFIX}strings"
