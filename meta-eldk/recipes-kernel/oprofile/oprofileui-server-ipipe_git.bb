require recipes-kernel/oprofile/oprofileui-server_git.bb

FILESEXTRAPATHS_prepend := "${THISDIR}/../../../meta/recipes-kernel/oprofile/oprofileui-server"

RDEPENDS_${PN} = "oprofile-ipipe"

SSTATE_DUPWHITELIST = "oprofileui-server"
