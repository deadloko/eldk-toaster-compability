#!/bin/sh

: ${MACHINE:="generic-powerpc"}

#
# The MIPS architecture is not supported by Xenomai, so build Xenomai
# images only for non-MIPS systems.
#
if expr "${MACHINE}" : "generic-mips" >/dev/null
then
	: MIPS architecture not supported by Xenomai
	XENO_IMG=""
else
	XENO_IMG="
		core-image-minimal-xenomai
		core-image-qte-xenomai-sdk
		meta-toolchain-xenomai-qte
	"
fi
		
: ${IMAGES:="
	core-image-minimal
	core-image-minimal-mtdutils
	core-image-minimal-dev
	core-image-base
	core-image-basic
	core-image-x11
	core-image-clutter
	core-image-lsb
	core-image-lsb-dev
	core-image-lsb-sdk
	core-image-sato
	core-image-sato-dev
	core-image-sato-sdk
	core-image-qte-sdk
	${XENO_IMG}
	meta-toolchain-sdk
	meta-toolchain-qte
"}

for image in $IMAGES ; do
	# Enable virtual terminals only for images with GUI
	# ("sato" and "qte" for now)
	#
	if expr "$image" : '.*\(sato\|qte\)' >/dev/null
	then
		use_vt=1
	else
		use_vt=0
	fi

	(
		date
		MACHINE=$MACHINE USE_VT=$use_vt bitbake $image
		date
	) 2>&1 | \
	tee BITBAKE-$image.LOG
done
