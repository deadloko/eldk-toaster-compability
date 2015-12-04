inherit image_types

# U-Boot format settings
UBOOT_SUFFIX ?= "bin"
UBOOT_PADDING ?= "0"

# Label of the boot partition
BOOTDD_VOLUME_ID ?= "Boot_${MACHINE}"

# Boot partition size [in KiB]
BOOT_SPACE ?= "65536"

# Image alignment [in KiB]
IMAGE_ROOTFS_ALIGNMENT = "4096"

# Path and name for the final .sdcard image
SDCARD = "${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.sdcard"

# General image dependencies
IMAGE_DEPENDS_sdcard = "parted-native dosfstools-native mtools-native virtual/kernel \
			u-boot genext2fs-native u-boot-mkimage-native"

IMAGE_CMD_sdcard() {
    if test -z "${SDCARD_ROOTFS}" ; then
	bberror "SDCARD_ROOTFS is undefined, define it in meta-eldk/conf/machine/${MACHINE}.conf ."
	exit 1
    fi

    # Align boot partition and calculate total SD card image size
    local boot_space_aligned=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
    boot_space_aligned=$(expr ${boot_space_aligned} - ${boot_space_aligned} % ${IMAGE_ROOTFS_ALIGNMENT})
    local sdcard_size=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${boot_space_aligned} + ${ROOTFS_SIZE} + ${IMAGE_ROOTFS_ALIGNMENT})


    # Initialize a sparse file
    dd if=/dev/zero of=${SDCARD} bs=1 count=0 seek=$(expr 1024 \* ${sdcard_size})

    ## Create an image that can by written onto a SD card using dd for use
    ## with i.MX SoC family
    ##
    ## External variables needed:
    ##   ${SDCARD_ROOTFS}    - the rootfs image to incorporate
    ##   ${IMAGE_BOOTLOADER} - bootloader to use
    ##
    ## The disk layout used is:
    ##
    ##    0                      -> IMAGE_ROOTFS_ALIGNMENT         - reserved to bootloader (not partitioned)
    ##    IMAGE_ROOTFS_ALIGNMENT -> BOOT_SPACE                     - kernel and other data
    ##    BOOT_SPACE             -> SDIMG_SIZE                     - rootfs
    ##
    ##                                                     Default Free space = 1.3x
    ##                                                     Use IMAGE_OVERHEAD_FACTOR to add more space
    ##                                                     <--------->
    ##            4MiB              64MiB           SDIMG_ROOTFS                    4MiB
    ## <-----------------------> <----------> <----------------------> <------------------------------>
    ##  ------------------------ ------------ ------------------------ -------------------------------
    ## | IMAGE_ROOTFS_ALIGNMENT | BOOT_SPACE | ROOTFS_SIZE            |     IMAGE_ROOTFS_ALIGNMENT    |
    ##  ------------------------ ------------ ------------------------ -------------------------------
    ## ^                        ^            ^                        ^                               ^
    ## |                        |            |                        |                               |
    ## 0                      4096     4MiB + 64MiB       4MiB + 64MiB + SDIMG_ROOTFS   4MiB + 64MiB + SDIMG_ROOTFS + 4MiB

    # Create the partition table
    parted -s ${SDCARD} mklabel msdos
    parted -s ${SDCARD} unit KiB mkpart primary ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${boot_space_aligned})
    parted -s ${SDCARD} unit KiB mkpart primary $(expr  ${IMAGE_ROOTFS_ALIGNMENT} \+ ${boot_space_aligned}) $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${boot_space_aligned} \+ $ROOTFS_SIZE)
    parted ${SDCARD} print

    # Write bootloader
    dd if=${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX} of=${SDCARD} conv=notrunc seek=2 skip=${UBOOT_PADDING} bs=512

    # Create boot partition image
    local boot_blocks=$(LC_ALL=C parted -s ${SDCARD} unit b print | awk '/ 1 / { print substr($4, 1, length($4 -1)) / 1024 }')

    # Create boot image
    IMAGE_BOOTFS="${WORKDIR}/boot-$(date +%Y%m%d%H%M%S)"
    test ! -e "${IMAGE_BOOTFS}"  && mkdir -p "${IMAGE_BOOTFS}"

    # Copy zImage
    cp "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin" "${IMAGE_BOOTFS}/${KERNEL_IMAGETYPE}"

    # Copy u-boot-with-nand-spl.imx into the boot partition
    cp -L "${DEPLOY_DIR_IMAGE}/u-boot-with-nand-spl-${MACHINE}.imx" "${IMAGE_BOOTFS}/u-boot-with-nand-spl.imx"

    # Copy dtb
    for dts in ${KERNEL_DEVICETREE}; do
        local dts_basename=$(basename ${dts} | awk -F "." '{print $1}')
        if test -e "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.dtb" ; then
            local kernel_bin="$(readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin)"
            local kernel_dtb="$(readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.dtb)"
            # Strip the file extension from the filename
            local kernel_bin_bn="$(echo ${kernel_bin} | sed 's/\.[^.]\+$//')"
            local kernel_dtb_bn="$(echo ${kernel_dtb} | sed 's/\.[^.]\+$//')"

            if test "${kernel_bin_bn}" = "${kernel_dtb_bn}" ; then
                cp "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.dtb" "${IMAGE_BOOTFS}/${dts_basename}.dtb"
            fi
        else
            die "there was a device tree in list, but it was not built"
        fi
    done

    # Produce fit-image.its
    cat << EOF > "${IMAGE_BOOTFS}/fit-image.its"
/dts-v1/;

/ {
        description = "Linux kernel and FDT blob for DENX M53EVK";
        #address-cells = <1>;

        images {
                kernel@1 {
                        description = "Linux kernel";
                        data = /incbin/("./zImage");
                        type = "kernel";
                        arch = "arm";
                        os = "linux";
                        compression = "none";
                        load = <0x70008000>;
                        entry = <0x70008000>;
                        hash@1 {
                                algo = "sha1";
                        };
                };
                fdt@1 {
                        description = "Flattened Device Tree blob";
                        data = /incbin/("./imx53-m53evk.dtb");
                        type = "flat_dt";
                        arch = "arm";
                        compression = "none";
                        hash@1 {
                                algo = "sha1";
                        };
                };
        };

        configurations {
                default = "conf@1";
                conf@1 {
                        description = "Boot Linux kernel with FDT blob";
                        kernel = "kernel@1";
                        fdt = "fdt@1";
                        hash@1 {
                                algo = "sha1";
                        };
                };
        };
};
EOF

    # Assemble the fitImage
    cwd=`pwd`
    cd "${IMAGE_BOOTFS}"
    mkimage -f "fit-image.its" fitImage
    cd "${cwd}"

    # Generate ext2 boot filesystem
    genext2fs -L "${BOOTDD_VOLUME_ID}" -b ${boot_blocks} -d ${IMAGE_BOOTFS} ${SDCARD_BOOTFS}

    # Write bootfs and rootfs image to the sdcard partition
    dd if=${SDCARD_BOOTFS} of=${SDCARD} conv=notrunc seek=1 bs=$(expr ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
    dd if=${SDCARD_ROOTFS} of=${SDCARD} conv=notrunc seek=1 bs=$(expr ${boot_space_aligned} \* 1024 + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
}

# Add /etc/pointercal and /usr/share/X11/xorg.conf.d/11-calibration.conf
# touchscreen calibration data so the touchscreen is pre-configured.
m53evk_add_ts_cal() {
	if [ -d ${IMAGE_ROOTFS}/etc/X11 ] ; then

		cat << EOF > ${IMAGE_ROOTFS}/usr/share/X11/xorg.conf.d/11-calibration.conf
Section "InputClass"
    Identifier         "touchscreen"
    MatchProduct       "stmpe-ts"
    MatchIsTouchscreen "on"
    MatchDevicePath    "/dev/input/event*"
    Driver             "tslib"
EndSection
EOF

	fi
	echo "-13266 64 52995992 -24 -8129 32716840 65536" > ${IMAGE_ROOTFS}/etc/pointercal
}

ROOTFS_POSTPROCESS_COMMAND += "m53evk_add_ts_cal ; "
