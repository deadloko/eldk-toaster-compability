require recipes-kernel/oprofile/oprofile_0.9.8.bb

FILESEXTRAPATHS_prepend := "${THISDIR}/../../../meta/recipes-kernel/oprofile/oprofile"

DEPENDS += " virtual/kernel-ipipe"

STAGING_KERNEL_DIR_append = "-xenomai"

BPN = "oprofile"

SSTATE_DUPWHITELIST = "oprofile"
