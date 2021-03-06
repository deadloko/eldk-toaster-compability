HOMEPAGE = "http://qt-project.org/"
DEPENDS = "gstreamer util-linux"

PACKAGECONFIG ??= "${@base_contains('DISTRO_FEATURES', 'pulseaudio', 'pulseaudio', '', d)} \
                   ${@base_contains('DISTRO_FEATURES', 'bluetooth', 'bluetooth', '', d)}"
PACKAGECONFIG[bluetooth] = ",,bluez4"
PACKAGECONFIG[pulseaudio] = ",,pulseaudio"

LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://LICENSE.LGPL;md5=fbc093901857fcd118f065f900982c24 \
		    file://LGPL_EXCEPTION.txt;md5=411080a56ff917a5a1aa08c98acae354"

FILESEXTRAPATHS =. "${FILE_DIRNAME}/qt-mobility-${PV}:"
SRC_URI = "http://get.qt.nokia.com/qt/add-ons/qt-mobility-opensource-src-${PV}.tar.gz \
           file://qt-mobility-configure.patch \
           file://0001-gstvideoconnector-fixed-buffers-allocation.patch \
           file://0002-Remove-unnecessary-rpaths-from-qml_device-example.patch \
           file://qt-mobility-no-opengl.patch \
           file://gcc-scope.patch \
           file://qt-mobility-no-xvideo.patch \
           file://0001-fix-embedded-usage-doesn-t-work-outside-of-Qt.patch \
           file://0001-Fix-for-playing-theora-encoded-videos.patch \
           file://0002-Support-playing-video-using-gst-omapfb-plugin.patch \
           file://0001-Avoid-omapfb-plane-setting-errors-on-first-player-st.patch \
	   "

SRC_URI[md5sum]="ea5db5a8d3dd4709c2926dceda646bd8"
SRC_URI[sha256sum]="ee3c88975e04139ac9589f76d4be646d44fcbc4c8c1cf2db621abc154cf0ba44"

PR = "r8"

S = "${WORKDIR}/qt-mobility-opensource-src-${PV}"

qtm_bin		:= "/usr/bin/${qtm_dir}"
qtm_lib		:= "/usr/lib"
qtm_include	:= "/usr/include/${qtm_dir}"
qtm_examples	:= "/usr/bin/${qtm_dir}/examples/QtMobility"
qtm_demos	:= "/usr/bin/${qtm_dir}/demos/QtMobility"
qtm_plugins	:= "/usr/lib/${qtm_dir}/plugins/QtMobility"
qtm_data	:= "/usr/share/${qtm_dir}"
qtm_imports	:= "/usr/lib/${qtm_dir}/imports"

QTM_MODULES_LIST ?= "bearer contacts gallery location publishsubscribe messaging multimedia \
systeminfo serviceframework sensors versit organizer feedback connectivity"

do_configure_prepend() {
	cp qtmobility.pro qtmobility.pro.old
	sed -e 's@...QT_INSTALL_DATA.@${qtm_data}@' <qtmobility.pro.old >qtmobility.pro
	for NAME in plugins/declarative/*/*.pro
	do
	    cp $NAME $NAME.old
	    sed -e 's@...QT_INSTALL_IMPORTS.@${qtm_imports}@' <$NAME.old >$NAME
	done
	cp staticconfig.pri staticconfig.pri.old
	echo "include(${STAGING_DATADIR}/${qtm_dir}/mkspecs/qconfig.pri)" >staticconfig.pri
	cat staticconfig.pri.old >>staticconfig.pri

        cat > features/platformconfig/oe.pri <<EOF
qmf_enabled = no
networkmanager_enabled = no
corewlan_enabled = no
immersion_enabled = no
meegotouchfeedback_enabled = no
maemo-icd_enabled = no
maemo-icd-network-wlan_enabled = no
maemo5-contacts_enabled = no
maemo5-calendar_enabled = no
maemo6-landmarks_enabled = no
bme_enabled = no
bluez_enabled = ${@base_contains('PACKAGECONFIG', 'bluetooth', 'yes', 'no', d)}
proj_enabled = no
gstreamer-photography_enabled = no
gstreamer-appsrc_enabled = yes
blkid_enabled = yes
pulseaudio_enabled = ${@base_contains('PACKAGECONFIG', 'pulseaudio', 'yes', 'no', d)}
udev_enabled = yes
iphb_enabled = no
nfc_symbian_enabled = no
sensord_enabled = no
geoclue-master_enabled = no
gypsy_enabled = no
${qtm_extra_config}
EOF

	./configure -qmake-exec qmake2 -prefix /usr -staticconfig oe -examples -demos -modules "${QTM_MODULES_LIST}"
	echo QT_MOBILITY_BIN = ${qtm_bin} >>./config.pri
	echo QT_MOBILITY_LIB = ${qtm_lib} >>./config.pri
	echo QT_MOBILITY_INCLUDE = ${qtm_include} >>./config.pri
	echo QT_MOBILITY_PLUGINS = ${qtm_plugins} >>./config.pri
	echo QT_MOBILITY_EXAMPLES = ${qtm_examples} >>./config.pri
	echo QT_MOBILITY_DEMOS = ${qtm_demos} >>./config.pri
	echo QT_CONFIG ${qtm_glflags} >>./config.pri
	echo CONFIG += ${qtm_embedded} >>./config.pri
}

do_compile_prepend() {
	for NAME in `find ./ -name Makefile` ; do
	    sed -e 's:-Wl,-rpath-link,${libdir}::g' -i $NAME 
	done
}

do_install() {
	for NAME in */*.prf
	do
	    cp $NAME $NAME.old
	    sed -e 's@/usr@${STAGING_BINDIR}/..@' <$NAME.old >$NAME
	done
	oe_runmake install INSTALL_ROOT=${D}
}

PACKAGES = "${PN}-dbg ${PN} ${PN}-dev"

FILES_${PN}-dbg = "${qtm_bin}/.debug ${qtm_examples}/.debug ${qtm_demos}/.debug \
                   ${qtm_lib}/.debug ${qtm_plugins}/*/.debug  ${qtm_imports}/*/.debug \
                   ${qtm_imports}/*/*/.debug ${bindir}/.debug /usr/src/debug"
FILES_${PN} = "${qtm_bin} ${qtm_examples} ${qtm_demos} ${qtm_lib}/*.so.1* ${qtm_plugins} ${qtm_imports}"
FILES_${PN}-dev = "${exec_prefix}"
