DESCRIPTION = "Linux Kernel"
SECTION = "kernel"
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

inherit kernel

# Strip the 'virtual/kernel' from ${PROVIDES} . This is important when trying
# to build and install both linux-eldk and linux-xenomai for the same machine.
# The kernel.bbclass adds 'virtual/kernel' into ${PROVIDES}, but when we build
# both linux-eldk and linux-xenomai, both inherit this linux.inc file and thus
# both contain 'virtual/kernel' in ${PROVIDES} . This causes Yocto to choke as
# there are two packages providing the same thing. The solution here is simple,
# strip the 'virtual/kernel' from ${PROVIDES} here and add virtual/kernel
# for main kernel and virtual/kernel-alternative for alternative
# the kernel packages. Which kernel package will provide 'virtual/kernel' is
# determined by the ${PREFERRED_PROVIDER_virtual/kernel} variable.
PROVIDES = "${@'${PN} virtual/kernel ' if '${PREFERRED_PROVIDER_virtual/kernel}' == '${PN}' else '${PN} virtual/kernel-ipipe '}"

# Define where the kernel headers are installed on the target as well as where
# they are staged.
KERNEL_DIR_SUFFIX = "${@'xenomai' if '${PN}' == 'linux-xenomai' else 'eldk'}"
KERNEL_SRC_PATH_append = '-${KERNEL_DIR_SUFFIX}'
KERNEL_LINK_PATH = "/usr/src/kernel"

DEPENDS_append = " u-boot-mkimage-native "
DEPENDS_append_em-x270 = " mtd-utils "

RPSRC = "http://www.rpsys.net/openzaurus/patches/archive"

# Specify the commandline for your device

#boot from mmc
CMDLINE_at91sam9263ek = "mem=64M console=ttyS0,115200 root=/dev/mmcblk0p1 rootfstype=ext2 rootdelay=5"
#boot from nfs
#CMDLINE_at91sam9263ek = "mem=64M console=ttyS0,115200 root=301 root=/dev/nfs nfsroot=172.20.3.1:/data/at91 ip=172.20.0.5:::255.255.0.0"

# Support for device tree generation
FILES_kernel-devicetree = "/boot/devicetree*"
FILES_kernel-dev += "${KERNEL_LINK_PATH}"

KERNEL_DEVICETREE_FLAGS = "-R 8 -p 0x3000"

python __anonymous () {
    import bb

    devicetree = d.getVar("KERNEL_DEVICETREE", 1) or ''
    if devicetree:
        depends = d.getVar("DEPENDS", 1)
        d.setVar("DEPENDS", "%s dtc-native" % depends)
        packages = d.getVar("PACKAGES", 1)
        d.setVar("PACKAGES", "%s kernel-devicetree" % packages)
}

do_configure_prepend() {
        echo "" > ${S}/.config

        #
        # logo support, if you supply logo_linux_clut224.ppm in SRC_URI, then it's going to be used
        #
        if [ -e ${WORKDIR}/logo_linux_clut224.ppm ]; then
                install -m 0644 ${WORKDIR}/logo_linux_clut224.ppm drivers/video/logo/logo_linux_clut224.ppm
                echo "CONFIG_LOGO=y"                    >> ${S}/.config
                echo "CONFIG_LOGO_LINUX_CLUT224=y"      >> ${S}/.config
        fi

        #
        # oabi / eabi support
        #
        if [ "${TARGET_OS}" = "linux-gnueabi" -o  "${TARGET_OS}" = "linux-uclibcgnueabi" ]; then
                echo "CONFIG_AEABI=y"                   >> ${S}/.config
                echo "# CONFIG_OABI_COMPAT is not set"             >> ${S}/.config
        else
                echo "# CONFIG_AEABI is not set"        >> ${S}/.config
                echo "# CONFIG_OABI_COMPAT is not set"  >> ${S}/.config
        fi

        echo "CONFIG_CMDLINE=\"${CMDLINE}\"" >> ${S}/.config

        sed -e '/CONFIG_AEABI/d' \
            -e '/CONFIG_OABI_COMPAT=/d' \
            -e '/CONFIG_CMDLINE=/d' \
            -e '/CONFIG_LOGO=/d' \
            -e '/CONFIG_LOGO_LINUX_CLUT224=/d' \
            < '${WORKDIR}/defconfig' >>'${S}/.config'

        #
        # root-over-nfs-over-usb-eth support. Limited, but should cover some cases.
        # Enable this by setting a proper CMDLINE_NFSROOT_USB.
        #
        if [ ! -z "${CMDLINE_NFSROOT_USB}" ]; then
                oenote "Configuring the kernel for root-over-nfs-over-usb-eth with CMDLINE ${CMDLINE_NFSROOT_USB}"
                sed -e '/CONFIG_INET/d' \
                    -e '/CONFIG_IP_PNP=/d' \
                    -e '/CONFIG_USB_GADGET=/d' \
                    -e '/CONFIG_USB_GADGET_SELECTED=/d' \
                    -e '/CONFIG_USB_ETH=/d' \
                    -e '/CONFIG_NFS_FS=/d' \
                    -e '/CONFIG_ROOT_NFS=/d' \
                    -e '/CONFIG_CMDLINE=/d' \
                    -i ${S}/.config
                echo "CONFIG_INET=y"                     >> ${S}/.config
                echo "CONFIG_IP_PNP=y"                   >> ${S}/.config
                echo "CONFIG_USB_GADGET=y"               >> ${S}/.config
                echo "CONFIG_USB_GADGET_SELECTED=y"      >> ${S}/.config
                echo "CONFIG_USB_ETH=y"                  >> ${S}/.config
                echo "CONFIG_NFS_FS=y"                   >> ${S}/.config
                echo "CONFIG_ROOT_NFS=y"                 >> ${S}/.config
                echo "CONFIG_CMDLINE=\"${CMDLINE_NFSROOT_USB}\"" >> ${S}/.config
        fi
        yes '' | oe_runmake oldconfig
}

kernel_do_install() {

	# from prepend

	# The first condition here makes sure that in case the kernel build
	# process generated arch/${ARCH}/boot/uImage already, but also did
	# generate arch/${ARCH}/boot/Image (which is the case on M28EVK and
	# M53EVK and other ARM systems for example), the uImage will NOT be
	# overwritten by a hardlink to Image. This would result in a bogus
	# resulting kernel image file, which would not be the correct uImage.
	if [ ! -e arch/${ARCH}/boot/uImage ] ; then
	        if test -e arch/${ARCH}/boot/Image ; then
		     ln -f arch/${ARCH}/boot/Image arch/${ARCH}/boot/uImage
	        fi

	        if test -e arch/${ARCH}/boot/images/uImage ; then
	             ln -f arch/${ARCH}/boot/images/uImage arch/${ARCH}/boot/uImage
	        fi
	fi

        if test -e arch/${ARCH}/kernel/vmlinux.lds ; then
             ln -f arch/${ARCH}/kernel/vmlinux.lds arch/${ARCH}/boot/vmlinux
        fi

        #
        # First install the modules
        #
        unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS MACHINE
        if (grep -q -i -e '^CONFIG_MODULES=y$' .config); then
                oe_runmake DEPMOD=echo INSTALL_MOD_PATH="${D}" modules_install
                rm -f "${D}/lib/modules/${KERNEL_VERSION}/modules.order"
                rm -f "${D}/lib/modules/${KERNEL_VERSION}/modules.builtin"
                rm "${D}/lib/modules/${KERNEL_VERSION}/build"
                rm "${D}/lib/modules/${KERNEL_VERSION}/source"
                if [ ! "$(ls -A ${D}/lib/modules/${KERNEL_VERSION}/kernel)"  ]; then
        	    rmdir ${D}/lib/modules/${KERNEL_VERSION}/kernel
                fi
                if [ ! "$(ls -A ${D}/lib/modules/${KERNEL_VERSION})"  ]; then
        	    rmdir ${D}/lib/modules/${KERNEL_VERSION}
                fi
                if [ ! "$(ls -A ${D}/lib/modules)"  ]; then
        	    rmdir ${D}/lib/modules
                fi
                if [ ! "$(ls -A ${D}/lib)"  ]; then
        	    rmdir ${D}/lib
                fi
        else
                bbnote "no modules to install"
        fi

        #
        # Install various kernel output (zImage, map file, config, module support files)
        #
        install -d ${D}/${KERNEL_IMAGEDEST}
        install -d ${D}/boot
        install -m 0644 ${KERNEL_OUTPUT} ${D}/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}
        install -m 0644 System.map ${D}/boot/System.map-${KERNEL_VERSION}
        install -m 0644 .config ${D}/boot/config-${KERNEL_VERSION}
        install -m 0644 vmlinux ${D}/boot/vmlinux-${KERNEL_VERSION}
        [ -e Module.symvers ] && install -m 0644 Module.symvers ${D}/boot/Module.symvers-${KERNEL_VERSION}
        install -d ${D}${sysconfdir}/modules-load.d
        install -d ${D}${sysconfdir}/modprobe.d

        #
        # Support for kernel source tree.
        #
        kerneldir=${D}${KERNEL_SRC_PATH}
        install -d $kerneldir

        #
        # Store the kernel version in sysroots for module-base.bbclass
        #
        echo "${KERNEL_VERSION}" > $kerneldir/kernel-abiversion

        #
        # Store kernel image name to allow use during image generation
        #
        echo "${KERNEL_IMAGE_BASE_NAME}" >$kerneldir/kernel-image-name

        #
        # Copy the entire source tree. In case an external build directory is
        # used, copy the build directory over first, then copy over the source
        # dir. This ensures the original Makefiles are used and not the
        # redirecting Makefiles in the build directory.
        #
        # work and sysroots can be on different partitions, so we can't rely on
        # hardlinking, unfortunately.
        #
        cp -fR * $kerneldir
        if [ "${S}" != "${B}" ]; then
                cp -fR ${S}/* $kerneldir
        fi

        #
        # Cleanup
        oe_runmake -C $kerneldir CC="${KERNEL_CC}" LD="${KERNEL_LD}" mrproper

        cp .config $kerneldir

	#
        # Store the kernel version in sysroots for module-base.bbclass
        #
        echo "${KERNEL_VERSION}" > $kerneldir/kernel-abiversion

        #
        # Store kernel image name to allow use during image generation
        #
        echo "${KERNEL_IMAGE_BASE_NAME}" >$kerneldir/kernel-image-name

	if [ "${PREFERRED_PROVIDER_virtual/kernel}" = "${PN}" ] ; then
		ln -sf kernel-${KERNEL_DIR_SUFFIX} ${D}${KERNEL_LINK_PATH}
	fi

        install -m 0644 ${KERNEL_OUTPUT} $kerneldir/${KERNEL_IMAGETYPE}
        install -m 0644 System.map $kerneldir/System.map-${KERNEL_VERSION}

	# from append
        if test -n "${KERNEL_DEVICETREE}"; then
	    DTB=${KERNEL_DEVICETREE}
	    if echo ${DTB} | grep -q '/dts/'; then
		    DTB=`basename ${DTB} | sed 's,\.dts$,.dtb,g'`
	    fi
	    DTB_BASE_NAME=`basename ${DTB} .dtb`
	    DTB_NAME=`echo ${KERNEL_IMAGE_BASE_NAME} | sed "s/${MACHINE}/${DTB_BASE_NAME}/g"`
	    DTB_SYMLINK_NAME=`echo ${KERNEL_IMAGE_SYMLINK_NAME} | sed "s/${MACHINE}/${DTB_BASE_NAME}/g"`
	    DTB_PATH="${B}/arch/${ARCH}/boot/dts/${DTB}"
	    oe_runmake ${DTB}
	    if [ ! -e "${DTB_PATH}" ]; then
		    DTB_PATH="${B}/arch/${ARCH}/boot/${DTB}"
	    fi

	    install -m 0644 ${DTB_PATH} ${D}/boot/devicetree-${KERNEL_VERSION}
            install -d ${DEPLOY_DIR_IMAGE}
            install -m 0644 ${DTB_PATH} ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGE_BASE_NAME}.dtb
            cd ${DEPLOY_DIR_IMAGE}
            rm -f ${KERNEL_IMAGE_SYMLINK_NAME}.dtb
            ln -sf ${KERNEL_IMAGE_BASE_NAME}.dtb ${KERNEL_IMAGE_SYMLINK_NAME}.dtb
        fi
}

pkg_postinst_kernel-dev_append () {
       # Fix the kernel source symlink when this package is installed via
       # packaging system.
       ln -sf kernel-${KERNEL_DIR_SUFFIX} ${D}${KERNEL_LINK_PATH}
}

SYSROOT_PREPROCESS_FUNCS += "linux_dev_fix_symlink"
linux_dev_fix_symlink() {
       # Fix the kernel source symlink when the sysroot is being populated.
       # This is absolutely important, otherwise stuff like lttng and such
       # which builds against the kernel source will fail to build.
       if [ "${PREFERRED_PROVIDER_virtual/kernel}" = "${PN}" ] ; then
               ln -sf kernel-${KERNEL_DIR_SUFFIX} ${SYSROOT_DESTDIR}${KERNEL_LINK_PATH}
       fi
}
