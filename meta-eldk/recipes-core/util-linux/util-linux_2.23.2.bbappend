# add nativesdk feature
FILESEXTRAPATHS_append := "${THISDIR}/util-linux:"
SRC_URI_append = "file://fix_nativendk_configure.patch \
		  file://Makefile_pkgconf.patch \
"

BBCLASSEXTEND += " nativesdk "
