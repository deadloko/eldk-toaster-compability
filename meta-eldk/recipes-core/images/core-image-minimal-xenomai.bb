SUMMARY = "Minimal root file system image with xenomai support"
DESCRIPTION = "Root FS includes the following functionality: \
		xenomai tools \
		"
PREFERRED_PROVIDER_virtual/linux-ipipe ?= "linux-xenomai"

DEPENDS_append = " ${PREFERRED_PROVIDER_virtual/linux-ipipe} "

IMAGE_INSTALL = "packagegroup-core-boot xenomai ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_LINGUAS = " "

IMAGE_DEVICE_TABLES = "files/device_table-minimal.txt files/device_table-xenomai.txt"

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE = "8192"

# remove not needed ipkg informations
ROOTFS_POSTPROCESS_COMMAND += "remove_packaging_data_files ; "
