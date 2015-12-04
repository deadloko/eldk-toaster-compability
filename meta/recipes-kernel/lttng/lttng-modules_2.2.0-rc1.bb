SECTION = "devel"
SUMMARY = "Linux Trace Toolkit KERNEL MODULE"
DESCRIPTION = "The lttng-modules 2.0 package contains the kernel tracer modules"
LICENSE = "LGPLv2.1 & GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1412caf5a1aa90d6a48588a4794c0eac \
                    file://gpl-2.0.txt;md5=751419260aa954499f7abaabaa882bbe \
                    file://lgpl-2.1.txt;md5=243b725d71bb5df4a1e5920b344b86ad"

DEPENDS = "virtual/kernel"

inherit module

SRCREV = "9a6800e3a7bed25af7a62d7e8cb2ad9a689e5877"
PV = "2.2.0-rc1"
PR = "r0"

SRC_URI = "git://git.lttng.org/lttng-modules.git;protocol=git \
           file://lttng-modules-replace-KERNELDIR-with-KERNEL_SRC-2.2.0-rc1.patch"

export INSTALL_MOD_DIR="kernel/lttng-modules"
export KERNEL_SRC="${STAGING_KERNEL_DIR}"


S = "${WORKDIR}/git"
