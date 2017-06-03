AC_INIT([budgie-calendar-applet], 0.1, [danielpinto8zz6@gmail.com], [budgie-calendar-applet], [https://github.com/danielpinto8zz6/budgie-calendar-applet])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC
LT_PREREQ(2.2)
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
LT_INIT([disable-static])
AC_CONFIG_MACRO_DIR([m4])

m4_define([budgie_required_version], [1])

# Note budgie-1.0 depends on peas, gtk, etc. Sorta your package managers
# business to make sure those deps are satisfied.
# Also note this is just for the C and Vala subprojects!
PKG_CHECK_MODULES(BUDGIE_PLUGIN,
        budgie-1.0 >= budgie_required_version
)

# Required only for Vala applets.
AM_PROG_VALAC([0.28], [], [AC_MSG_ERROR([valac is required to build Vala applets])])

AC_CONFIG_FILES([Makefile
                 budgie-calendar-applet/Makefile])

AC_OUTPUT

AC_MSG_RESULT([
        budgie-desktop-examples $VERSION
        ========

        prefix:                 ${prefix}
        libdir:                 ${libdir}
        sysconfdir:             ${sysconfdir}
        exec_prefix:            ${exec_prefix}
        bindir:                 ${bindir}
        datarootdir:            ${datarootdir}

        compiler:               ${CC}
        cflags:                 ${CFLAGS}
        ldflags:                ${LDFLAGS}
])
