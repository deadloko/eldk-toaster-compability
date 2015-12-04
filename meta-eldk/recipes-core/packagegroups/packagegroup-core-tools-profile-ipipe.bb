require recipes-core/packagegroups/packagegroup-core-tools-profile.bb

LTTNGMODULES = "lttng-modules-ipipe"

RRECOMMENDS_${PN} = "\
    perf-ipipe \
    trace-cmd \
    kernel-module-oprofile \
    blktrace \
    ${PROFILE_TOOLS_X} \
"

PROFILETOOLS = "\
    oprofile-ipipe \
    oprofileui-server-ipipe \
    powertop \
    latencytop \
"


