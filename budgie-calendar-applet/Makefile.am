include $(top_srcdir)/common.mk

EXTRA_DIST =
pkglib_LTLIBRARIES =
plugindir = $(libdir)/budgie-desktop/plugins
calendarapplet_DATA =

%.plugin: %.plugin.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po)
	$(AM_V_GEN) \
	$(MKDIR_P) "$(dir $@)"; \
	$(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

calendarapplet_DATA += \
	CalendarApplet.plugin

EXTRA_DIST += \
	CalendarApplet.plugin.in

CLEANFILES = \
	CalendarApplet.plugin

DISTCLEANFILES = \
	CalendarApplet.plugin

calendarappletdir = $(plugindir)/budgie-calendar-applet

calendarapplet_LTLIBRARIES = \
	libcalendarapplet.la

libcalendarapplet_la_SOURCES = \
	CalendarApplet.vala

libcalendarapplet_la_CFLAGS = \
	$(BUDGIE_PLUGIN_CFLAGS) \
	-DPACKAGE_LOCALEDIR=\""$(datadir)/locale"\" \
	-include $(CONFIG_HEADER)

libcalendarapplet_la_LIBADD = \
	$(BUDGIE_PLUGIN_LIBS)

libcalendarapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	-shared \
	$(AM_LDFLAGS)

libcalendarapplet_la_VALAFLAGS = \
	--pkg budgie-1.0 \
	--vapidir ${top_srcdir}/vapi \
	--pkg config


