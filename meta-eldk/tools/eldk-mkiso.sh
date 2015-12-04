#!/bin/sh

# (C) Copyright 2011-2013 Wolfgang Denk, DENX Software Engineering GmbH
#
# Licensed under the GPLv2 or later.

ELDK_VERSION="5.5"

# Verify that we are running in the right directory
# And that all needed files exist
FILES="
	README
	install.sh
	install.sha256
"

[ $# -gt 1 ] || {
	echo "Usage: $(basename $0) iso_img arch ..." >&2
	exit 1
}
OUTFILE="$1"
shift

for i in $FILES ; do
	[ -r "$i" ] || {
		echo "File '$i' does not exist" >&2
		exit 1
	}
done

tmp_dir=$(mktemp -d /tmp/eldk_geniso.XXXXX) || exit 1

trap 'rm -fr $tmp_dir' 0 1 2 3 15

echo "## Copy common files..." >&2
for i in $FILES ; do
	echo $i
done | cpio --quiet -Bpdum $tmp_dir

# make sure the ISO image can be read by others
chmod 0755 $tmp_dir

for arch in "$@" ;
do
	# Verify arguments: must be existing target architectures
	# Also verify that the minimally needed files exist

	dir="targets/$arch"
	[ -d "$dir" ] || {
		echo "Directory '$dir' does not exist" >&2
		exit 1
	}
	[ -f "$dir/$arch.sha256" ] || {
		echo "File '$dir/$arch.sha256' does not exist" >&2
		exit 1
	}
	[ -f "$dir/target.conf" ] || {
		echo "File '$dir/target.conf' does not exist" >&2
		exit 1
	}
	echo "## Copy files for target architecture ${arch}..." >&2
	find "$dir" | cpio --quiet -Bpdum $tmp_dir/
done

echo "## Generate ISO image '${OUTFILE}'..." >&2
genisoimage \
	-quiet \
	-input-charset=utf-8 \
	-R -J \
	-A "ELDK v${ELDK_VERSION}" \
	-V "ELDK v${ELDK_VERSION}   $(date '+%Y-%m-%d')" \
	-publisher "DENX Software Engineering GmbH  www.denx.de office@denx.de" \
	-preparer  "Wolfgang Denk <wd@denx.de>" \
	-iso-level=3 \
	-o ${OUTFILE} \
	$tmp_dir
