require ../linux/linux.inc

LINUX_VER="${@d.getVar('PV',1).split('-')[0]}"
LINUX_VER_SHORT="${@d.getVar('LINUX_VER',1).split('.')[0]}.${@d.getVar('LINUX_VER',1).split('.')[1]}"

PROVIDES_append = "kernel-ipipe-base kernel-ipipe-image kernel-ipipe-dev \
	           kernel-ipipe-vmlinux kernel-ipipe-modules kernel-ipipe-devicetree"

XENOMAI_VER="2.6.3"

XENOMAI_SRC_PATH = "../xenomai"

SRC_URI = "http://download.gna.org/xenomai/stable/xenomai-${XENOMAI_VER}.tar.bz2;name=xenomai"

SRC_URI[xenomai.md5sum] = "9f83c39cfb10535df6bf51702714e716"
SRC_URI[xenomai.sha256sum] = "4d0d09431f0340cf4c9e2745177f77f15b7b124f89982035d1d3586519d7afe9"

DEPENDS_append = " xenomai"

S="${WORKDIR}/git"

do_configure_prepend() {
	# proceed xenomai patching
	${WORKDIR}/xenomai-${XENOMAI_VER}/scripts/prepare-kernel.sh --arch=${ARCH} \
	    --adeos=${WORKDIR}/xenomai-${XENOMAI_VER}/ksrc/arch/${ARCH}/patches/*ipipe*${LINUX_VER_SHORT}*${ARCH}*.patch \
        --linux=${S}
}

kernel_do_install_append() {
	cd $kerneldir
	# change xenomai soft links
	find . -regex ".*xenomai.*" -type l -printf "export pathto=\`echo %p | sed -e 's@[^/]*/@../@g' \`; \
		export linkfile=\`readlink %p | sed 's@.*xenomai-${XENOMAI_VER}@@'\`; \
		export linkto=\$(dirname \$(dirname \$pathto))/${XENOMAI_SRC_PATH}\$linkfile ; \
		rm %p; ln -s \$linkto %p \n" | sh
}

# kernel-ipipe-base becomes kernel-ipipe-${KERNEL_VERSION}
# kernel-ipipe-image becomes kernel-ipipe-image-${KERNEL_VERISON}
PACKAGES = "kernel kernel-ipipe kernel-ipipe-base kernel-ipipe-vmlinux kernel-ipipe-image kernel-ipipe-dev kernel-ipipe-modules kernel-ipipe-devicetree"
FILES_kernel-ipipe-base = '${FILES_kernel-base}'
FILES_kernel-ipipe-image = '${FILES_kernel-image}'
FILES_kernel-ipipe-dev = '${FILES_kernel-dev}'
FILES_kernel-ipipe-vmlinux = '${FILES_kernel-vmlinux}'
FILES_kernel-ipipe-modules = '${FILES_kernel-modules}'
FILES_kernel-ipipe-devicetree = '${FILES_kernel-devicetree}'
RDEPENDS_kernel-ipipe = "kernel-ipipe-base"
RDEPENDS_kernel = "kernel-ipipe"
# Allow machines to override this dependency if kernel-ipipe image files are 
# not wanted in images as standard
RDEPENDS_kernel-ipipe-base ?= "kernel-ipipe-image"
PKG_kernel-ipipe-image = "kernel-ipipe-image-${@legitimize_package_name('${KERNEL_VERSION}')}"
PKG_kernel-ipipe-base = "kernel-ipipe-${@legitimize_package_name('${KERNEL_VERSION}')}"
PKG_kernel = "kernel-${@legitimize_package_name('${KERNEL_VERSION}')}"
RPROVIDES_kernel-ipipe-base += "kernel-ipipe-${KERNEL_VERSION}"
ALLOW_EMPTY_kernel-ipipe = "1"
ALLOW_EMPTY_kernel-ipipe-base = "1"
ALLOW_EMPTY_kernel-ipipe-image = "1"
ALLOW_EMPTY_kernel-ipipe-modules = "1"
DESCRIPTION_kernel-ipipe-modules = "Kernel modules meta package"

KERNEL_MODULES_META_PACKAGE = "kernel-ipipe-modules"
KERNEL_MODULES_PACKAGE_PATTERN = "kernel-ipipe-module-"
