# add_machine_symlink class adds additional symlinks that not included to packages by default - it 
# genertae QA error at building time. This extension allow to includes files to the package

inherit add_machine_symlinks

MACHINE_STRIPPED = "${@d.getVar(['MACHINE', 'MACHINE_NO_GENERIC'][d.getVar('MACHINE', 1).startswith('generic-')], 1)}"

FILES_${PN}-symlinks += "\
  ${bindir}/${MACHINE_STRIPPED}*-cc \
  ${bindir}/${MACHINE_STRIPPED}*-gcc \
  ${bindir}/${MACHINE_STRIPPED}*-gccbug \
  ${bindir}/${MACHINE_STRIPPED}*-gcc-nm \
  ${bindir}/${MACHINE_STRIPPED}*-gcc-ar \
  ${bindir}/${MACHINE_STRIPPED}*-gcc-ranlib \
"

FILES_cpp-symlinks += "\
    ${bindir}/${MACHINE_STRIPPED}*-cpp \
"

FILES_gcov-symlinks += "\
  ${bindir}/${MACHINE_STRIPPED}*-gcov \
"

FILES_g++-symlinks += "\
  ${bindir}/${MACHINE_STRIPPED}*-c++ \
  ${bindir}/${MACHINE_STRIPPED}*-g++ \
"
