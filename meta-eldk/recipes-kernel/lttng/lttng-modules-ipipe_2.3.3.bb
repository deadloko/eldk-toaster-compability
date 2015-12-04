require recipes-kernel/lttng/lttng-modules_2.3.3.bb

FILESEXTRAPATHS_prepend := "${THISDIR}/../../../meta/recipes-kernel/lttng/lttng-modules"

DEPENDS = "virtual/kernel-ipipe"

STAGING_KERNEL_DIR_append = "-xenomai"

export KERNEL_MODULES_PACKAGE_PATTERN="ipipe-"

SSTATE_DUPWHITELIST="lttng"
