require recipes-kernel/perf/perf.bb

PERF_FEATURES_ENABLE ?= ""

EXTRA_OEMAKE += "\
		NO_NEWT=1 \
		"

DEPENDS += " virtual/kernel-ipipe"

SSTATE_DUPWHITELIST = "perf"

STAGING_KERNEL_DIR_append = "-xenomai"

do_compile_append() {
	if [ ! -e ${B}/.config ]; then
		cp ${S}/.config ${B}
	fi

	if [ ! -e ${S}/include/generated/utsrelease.h ]; then
	
    	    cd ${STAGING_KERNEL_DIR}
	    oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
	           -C ${STAGING_KERNEL_DIR} include/config/kernel.release oldconfig
    	    oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" AR="${KERNEL_AR}" \
            	    -C ${STAGING_KERNEL_DIR} include/generated/utsrelease.h

	    if [ ! -e ${S}/include/generated ]; then
		mkdir ${S}/include/generated
	    fi
	    if [ ! -e ${S}/include/generated/utsrelease.h ]; then
		cp ${B}/include/generated/utsrelease.h ${S}/include/generated
	    fi
	fi
}
