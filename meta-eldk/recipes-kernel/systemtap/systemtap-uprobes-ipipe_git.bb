require recipes-kernel/systemtap/systemtap-uprobes_git.bb

FILESPATH = "${THISDIR}/../../../meta/recipes-kernel/systemtap/systemtap"

DEPENDS = "systemtap virtual/kernel-ipipe"

STAGING_KERNEL_DIR_append = "-xenomai"

SSTATE_DUPWHITELIST = "systemtap-uprobes"
