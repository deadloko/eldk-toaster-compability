include ../../meta/classes/module.bbclass

do_make_scripts_append() {
	oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
	           -C ${STAGING_KERNEL_DIR} include/config/kernel.release oldconfig
	oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
	           -C ${STAGING_KERNEL_DIR} modules_prepare
}

do_make_scripts_append_powerpc() {
	oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
	           -C ${STAGING_KERNEL_DIR} arch/powerpc/lib/crtsavres.o
}
