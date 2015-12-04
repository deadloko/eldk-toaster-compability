# Add support for non-standard console names; by default, the device
# names used in the SERIAL_CONSOLES definition are supposed to match
# the "tty*" wildcard.  With ELDK's generic cofigurations, we
# frequently use the generic "console" name instead.
#
# If the "tty*" wildcard does not match, we also generate standard ID
# field in the form "S<n>", where "n" is an incrementing number,
# starting with 0.

do_install() {
	install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/inittab ${D}${sysconfdir}/inittab

    tmp="${SERIAL_CONSOLES}"
    k=0
    for i in $tmp
    do
	j=`echo ${i} | sed s/\;/\ /g`
	if [ "${i}" = `echo ${i} | sed -e 's/^.*;tty//'` ]; then
		label="S$k"
		k=`expr $k + 1`
	else
		label=`echo ${i} | sed -e 's/^.*;tty//' -e 's/;.*//'`
	fi
	echo "$label:12345:respawn:${base_sbindir}/getty ${j}" >> ${D}${sysconfdir}/inittab
    done

    if [ "${USE_VT}" = "1" ]; then
        cat <<EOF >>${D}${sysconfdir}/inittab
# ${base_sbindir}/getty invocations for the runlevels.
#
# Format:
#  <id>:<runlevels>:<action>:<process>
#

EOF

        for n in ${SYSVINIT_ENABLED_GETTYS}
        do
            echo "$n:2345:respawn:${base_sbindir}/getty 38400 tty$n" >> ${D}${sysconfdir}/inittab
        done
        echo "" >> ${D}${sysconfdir}/inittab
    fi
}
