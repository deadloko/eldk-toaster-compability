# Add additional stubs generation for mips target. 

do_install_prepend_mips () {
    oe_runmake installed-stubs="${D}${includedir}/gnu/stubs-o32_soft.h ${D}${includedir}/gnu/stubs-o32_hard.h" install_root=${D} install
}
