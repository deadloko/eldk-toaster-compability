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

# Special u-boot.sd and u-boot.nand interim result dependiencies
IMAGE_DEPENDS_u-boot.sd = "u-boot-mkimage-native u-boot"
IMAGE_CMD_u-boot.sd = "mxsboot sd ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.u-boot.sd"
IMAGE_DEPENDS_u-boot.nand = "u-boot-mkimage-native u-boot"
IMAGE_CMD_u-boot.nand = "mxsboot nand ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.${UBOOT_SUFFIX} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.u-boot.nand"

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

    ## The disk layout used is:
    ##
    ##    1M                     -> 2M                             - reserved to bootloader and other data
    ##    2M                     -> BOOT_SPACE                     - kernel and other data
    ##    BOOT_SPACE             -> SDIMG_SIZE                     - rootfs
    ##
    ##                                                        Default Free space = 1.3x
    ##                                                        Use IMAGE_OVERHEAD_FACTOR to add more space
    ##                                                        <--------->
    ##            4MiB                64MiB            SDIMG_ROOTFS                    4MiB
    ## <-----------------------> <-------------> <----------------------> <------------------------------>
    ##  ---------------------------------------- ------------------------ -------------------------------
    ## |      |      |                          |ROOTFS_SIZE             |     IMAGE_ROOTFS_ALIGNMENT    |
    ##  ---------------------------------------- ------------------------ -------------------------------
    ## ^      ^      ^          ^               ^                        ^                               ^
    ## |      |      |          |               |                        |                               |
    ## 0     1M     2M         4M        4MiB + BOOTSPACE   4MiB + BOOTSPACE + SDIMG_ROOTFS   4MiB + BOOTSPACE + SDIMG_ROOTFS + 4MiB
    ##

    # Create the partition table
    parted -s ${SDCARD} mklabel msdos
    parted -s ${SDCARD} unit KiB mkpart primary 1024 2048
    parted -s ${SDCARD} unit KiB mkpart primary 2048 $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${boot_space_aligned})
    parted -s ${SDCARD} unit KiB mkpart primary $(expr  ${IMAGE_ROOTFS_ALIGNMENT} \+ ${boot_space_aligned}) $(expr ${IMAGE_ROOTFS_ALIGNMENT} \+ ${boot_space_aligned} \+ $ROOTFS_SIZE)

    # Write bootloader
    dd if=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.u-boot.sd of=${SDCARD} conv=notrunc seek=1 skip=${UBOOT_PADDING} bs=$(expr 1024 \* 1024)

    # Create boot partition image
    local boot_blocks=$(LC_ALL=C parted -s ${SDCARD} unit b print | awk '/ 2 / { print substr($4, 1, length($4 -1)) / 1024 }')

    # Create boot image
    IMAGE_BOOTFS="${WORKDIR}/boot-$(date +%Y%m%d%H%M%S)"
    test ! -e "${IMAGE_BOOTFS}" && mkdir -p "${IMAGE_BOOTFS}"

    # Copy zImage
    cp "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin" "${IMAGE_BOOTFS}/${KERNEL_IMAGETYPE}"

    # Copy u-boot.nand into the boot partition
    cp "${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.u-boot.nand" "${IMAGE_BOOTFS}/u-boot.nand"

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
        description = "Linux kernel and FDT blob for DENX M28EVK";
        #address-cells = <1>;

        images {
                kernel@1 {
                        description = "Linux kernel";
                        data = /incbin/("./zImage");
                        type = "kernel";
                        arch = "arm";
                        os = "linux";
                        compression = "none";
                        load = <0x40008000>;
                        entry = <0x40008000>;
                        hash@1 {
                                algo = "sha1";
                        };
                };
                fdt@1 {
                        description = "Flattened Device Tree blob";
                        data = /incbin/("./imx28-m28evk.dtb");
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

    # Write it to the sdcard partition
    dd if=${SDCARD_BOOTFS} of=${SDCARD} conv=notrunc seek=2 bs=$(expr 1024 \* 1024)

    # Change partition type for partition 1 so the MXS BootROM will pick it up
    bbnote "Setting partition type to 0x53 as required for mxs' SoC family."
    echo -n S | dd of=${SDCARD} bs=1 count=1 seek=450 conv=notrunc
    parted ${SDCARD} print

    # Write rootfs image
    dd if=${SDCARD_ROOTFS} of=${SDCARD} conv=notrunc seek=1 bs=$(expr ${boot_space_aligned} \* 1024 + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
}

# Add /etc/pointercal and /usr/share/X11/xorg.conf.d/11-calibration.conf
# touchscreen calibration data so the touchscreen is pre-configured.
m28evk_add_ts_cal() {
	if [ -d ${IMAGE_ROOTFS}/etc/X11 ] ; then

		cat << EOF > ${IMAGE_ROOTFS}/usr/share/X11/xorg.conf.d/11-calibration.conf
Section "InputClass"
    Identifier         "touchscreen"
    MatchProduct       "mxs-lradc"
    MatchIsTouchscreen "on"
    MatchDevicePath    "/dev/input/event*"
    Driver             "tslib"
EndSection
EOF

	fi
	echo "13324 39 -1639788 10 -8255 33154716 65536" > ${IMAGE_ROOTFS}/etc/pointercal
}

ROOTFS_POSTPROCESS_COMMAND += "m28evk_add_ts_cal ; "
