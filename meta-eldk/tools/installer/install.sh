#!/bin/bash

# (C) Copyright 2011-2013  DENX Software Engineering GmbH
#
# Licensed under the GPLv2 or later.

ELDK_VERSION="5.5"
default_path="/opt/eldk-${ELDK_VERSION}"

SRC_DIR=$(dirname $0)

SDK_ARCH=i686

# Available SDK image types (first in list is default)
: ${SDK_KNOWN_IMAGES:="
	gmae
	qte
	qte-xenomai
"}

: ${SDK_IMAGES:="gmae"}

# Available Root File System image types (first in list is default)
: ${RFS_KNOWN_IMAGES:="
	minimal
	minimal-mtdutils
	minimal-dev
	minimal-xenomai
	base
	basic
	clutter
	lsb
	lsb-dev
	lsb-sdk
	sato
	sato-dev
	sato-sdk
	qte-sdk
	qte-xenomai-sdk
	x11
"}

: ${RFS_IMAGES:="${RFS_KNOWN_IMAGES}"}

list_known_images()
{
	type=$1
	shift

	local list=""

	deflt=""
	for i in $(eval echo \$${type}_KNOWN_IMAGES) ; do
		if [ -z "$list" ] ; then
			list="'$i'"
			deflt="$i"
		else
			list="$list, '$i'"
		fi
	done
	eval ${type}_LIST=\"$list\"
	eval ${type}_DEFAULT=\"$deflt\"
}

list_available_images()
{
	type="$1"
	prefix="$2"
	suffix="$3"

	local list=""

	# Note: avoid "while read i ; do ... done" here as
	# 'while' starts a sub-shell, and we cannot access
	# the variables set inside this loop after it end.
	for i in $(
		cd ${SRC_DIR}/targets/${target}
		# try without and with popular compressions
		ls ${prefix}*${suffix}     2>/dev/null
		ls ${prefix}*${suffix}.gz  2>/dev/null
		ls ${prefix}*${suffix}.xz  2>/dev/null
		ls ${prefix}*${suffix}.bz2 2>/dev/null
	)
	do
		i=${i#$prefix}
		i=${i%.gz}
		i=${i%.xz}
		i=${i%.bz2}
		i=${i%$suffix}
		if [ -z "$list" ] ; then
			list="$i" 
		else
			list="$list $i"
		fi
		# echo "## L: $list"

	done
	# echo "## LIST: $list"
	eval ${type}_AVAIL=\"$list\"
}

print_available_images()
{
	local name=$1
	shift

	echo "Available ${name} images for target '${target}':"
	(
		sep=" "
		echo -e '|       \c'
		for i in $* ; do
			echo -e "${sep}'${i}'\c"
			sep=", "
		done
		if [ "${sep}" = " " ] ; then
			echo ' <none>'
		else
			echo '.'
		fi
	) | fmt -u -p '|' | tr -d '|' >&2
}

list_known_images SDK
list_known_images RFS

usage() {
	my_name=$(basename $0)
	fmt -u -p '|' <<E_O_F | tr '|' ' ' >&2

Usage: ${my_name} [-D] [-d <dir>] [-a <arch>] [-s <sdk_img> ] [-r <rfs_img> ] [<target>]
       ${my_name} -l [<target>]
       ${my_name} -h
-D: Dry-run: display commands, but don't actually execute them.
-a: SDK host architecture.
|   Chose one of 'i686' or 'x86_64".
    Defaults to "${SDK_ARCH}".
-d: Destination directory.
    Defaults to "${default_path}"
-h: Help: print this message.
-l: List available SDK and RFS images
-s: Select SDK image.
|   Chose one of ${SDK_LIST}, or '-' for none.
    Defaults to "${SDK_DEFAULT}".
-r: Select list of target RFS images.
|   Chose one or more of ${RFS_LIST}, or '-' for none.
    Defaults to all.

<target>  target architecture, defaults to "armv7a-hf"
E_O_F
}

dest_path=""
list_only=""
DRY_RUN=""

while getopts "Da:d:hlr:s:" option; do
	case "$option" in
	D) DRY_RUN="echo ###" ;;
	a) SDK_ARCH="$OPTARG" ;;
	d) dest_path="$OPTARG" ;;
	h) usage ; exit 0 ;;
	l) list_only=yes ;;
	r) RFS_IMAGES="$OPTARG" ;;
	s) SDK_IMAGES="$OPTARG" ;;
	*) usage ; exit 1 ;;
	esac
done
shift $((OPTIND - 1))

if [ $# -gt 2 ] ; then
	echo "Error: too many argumentes ($#, max is 2)" >&2
	usage
	exit 1
fi

# First argument is the target name (defaults to armv7a-hf)
target=${1:-"armv7a-hf"}

target_dir="${SRC_DIR}/targets/${target}"
if [ ! -d "${target_dir}" ] ; then
	echo "Error: target directory \"${target_dir}\" does not exist" >&2
	exit 1
fi

# try to load target configuration
target_conf="${target_dir}/target.conf"
if [ ! -r ${target_conf} ] ; then
	echo "Error: can't read target config file \"${target_conf}\"" >&2
	exit 1
fi

. ${target_conf}

# Currently we support only i686 and x86_64 hosts
cur_arch=$(uname -m)

case ${cur_arch} in
i686) ;;
x86_64) ;;
*)
	echo "You are running neither on i686 nor x86_64 machine" >&2
	echo "Your machine is not supported" >&2
	exit 1
	;;
esac

SDK_OS="linux"
SDK_VENDOR="-eldk"

case ${SDK_ARCH} in
i686) ;;
x86_64) ;;
*)
	echo "Error: SDK architecture \"${SDK_ARCH}\" is not supported" >&2
	exit 1
	;;
esac

list_available_images SDK \
	eldk-eglibc-${SDK_ARCH}-${TARGET_ARCH}-toolchain- \
	-${ELDK_VERSION}.sh
#echo "AVAILABLE SDK IMAGES: ${SDK_AVAIL}"

list_available_images RFS \
	core-image- \
	-generic-${MACHINE}.tar
# echo "AVAILABLE RFS IMAGES: ${RFS_AVAIL}"

if [ "${list_only}" = "yes" ] ; then
	print_available_images SDK ${SDK_AVAIL}
	print_available_images RFS ${RFS_AVAIL}

	exit 0
fi

: ${dest_path:="${default_path}"}
inst_path="${dest_path}/${MACHINE}"

# Install SDK first

if [ "${SDK_IMAGES}" != "-" ] ; then

	# Check if the SDK images we are about to install actually exist.
	# Note: so far we install only one SDK image, so the code could be
	# simpler, but we allow for future extensions.
	#
	for img in ${SDK_IMAGES}; do
		found=""
		for avail in ${SDK_AVAIL} ; do
			if [ "$img" = "$avail" ] ; then
				found=yes
				break
			fi
		done
		if [ -z "$found" ] ; then
			echo "Error: SDK image \"${img}\" is not available" >&2
			print_available_images SDK ${SDK_AVAIL}
			exit 1
		fi

		shar=$(echo ${SRC_DIR}/targets/${target}/\
eldk-eglibc-${SDK_ARCH}-${TARGET_ARCH}-toolchain-${img}-${ELDK_VERSION}.sh)

		if [ ! -r "${shar}" ] ; then
			echo "Error: Can't read SDK shell archive \"${shar}\"" >&2
			exit 1
		fi
	
		sdk_path="${inst_path}/sysroots"
	
		if [ -e ${sdk_path} ] ; then
			echo "Error: installation directory \"${sdk_path}\" already exists" >&2
			exit 1
		fi
		if ${DRY_RUN} mkdir -p ${inst_path} >/dev/null ; then
			:
		else
			${DRY_RUN} cat >&2 <<E_O_F
--------------------------------------------------------------------
NOTICE: superuser priviledges will be needed to create the
installation directory; make sure you have sufficient permissions.
--------------------------------------------------------------------
E_O_F
			${DRY_RUN} sudo mkdir -p ${inst_path} || exit 1
			${DRY_RUN} sudo chown $(id -n -u).$(id -n -g) ${inst_path} || exit 1
		fi
		echo -e "*** Installing ${shar}\n    into ${inst_path}" >&2

		echo -e "${inst_path}\ny" | \
		${DRY_RUN} sh ${shar} >/dev/null || exit 1
	done
fi

# Then install RFS images

if [ "${RFS_IMAGES}" != "-" ] ; then

	${DRY_RUN} cat >&2 <<E_O_F
--------------------------------------------------------------------
NOTICE: superuser priviledges will be needed to install the
root file system; make sure you have sufficient permissions.
--------------------------------------------------------------------
E_O_F

	# Check if the RFS images we are about to install actually exist.
	#
	for img in ${RFS_IMAGES}; do
		found=""
		for avail in ${RFS_AVAIL} ; do
			if [ "$img" = "$avail" ] ; then
				found=yes
				break
			fi
		done
		if [ -z "$found" ] ; then
			echo "Error: RFS image \"${img}\" is not available" >&2
			print_available_images RFS ${RFS_AVAIL}
			exit 1
		fi

		tarball=$(echo ${SRC_DIR}/targets/${target}/\
core-image-${img}-generic-${MACHINE}.tar*)

		if [ ! -r "${tarball}" ] ; then
			echo "Error: Can't read rootfs tarball \"${tarball}\"" >&2
			exit 1
		fi
	
		rootfs_path="${inst_path}/rootfs-${img}"
	
		if [ -e ${rootfs_path} ] ; then
			echo "Error: installation directory \"${rootfs_path}\" already exists" >&2
			exit 1
		fi
	
		${DRY_RUN} mkdir -p ${rootfs_path} || exit 1
		echo -e "*** Installing ${tarball}\n    into ${rootfs_path}" >&2
		${DRY_RUN} sudo tar xpf ${tarball} -C ${rootfs_path}
	done
fi

exit 0
