# simple class to add symlinks to the tools
# it works by searching the installation directory for the names beginning
# with the ${TARGET_ARCH}-${TARGET_OS}${TARGET_VENDOR}- and adds symlinks
# in the form ${MACHINE}-<toolname>.
# TODO: It would be better to work with ${PACKAGES} and
# ${FILES_<package_name>} instead of dealing with the installation tree
# directly to ensure that newly created symlinks would be actually
# packaged but this method doesn't work for me for some reason. Currently
# there will be a warring message for every unpackaged symlink.

# tool prefix we are searching for
tool_prefix="${TARGET_ARCH}-${TARGET_OS}${TARGET_VENDOR}"

# Strip the "generic-" from machine name
MACHINE_NO_GENERIC = "${@d.getVar('MACHINE', 1).replace('generic-', '')}"
MACHINE_STRIPPED = "${@d.getVar(['MACHINE', 'MACHINE_NO_GENERIC'][d.getVar('MACHINE', 1).startswith('generic-')], 1)}"

do_add_machine_symlinks () {
	# ignore crosssdk packages
	if echo ${PN} | grep crosssdk ; then
		return 0
	fi

	# ignore crosssdk packages
	if echo ${PN} | grep "packagegroup-" ; then
		return 0
	fi

	files=`find ${D} -type f`
	for i in $files; do
		t=`basename $i`
		if echo $t | grep -v "^${tool_prefix}-"; then
			continue
		fi
		d=`dirname $i`
		l=`echo $t | sed "s/${tool_prefix}//"`
		if [ ! -e $d/${MACHINE_STRIPPED}$l ];  then
			ln -s $t $d/${MACHINE_STRIPPED}$l
		fi
	done
	true
}

addtask add_machine_symlinks after do_install before do_package

