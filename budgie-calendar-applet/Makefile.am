plugindir = $(libdir)/budgie-desktop/plugins

calendarappletdir = $(plugindir)/budgie-calendar-applet

calendarapplet_LTLIBRARIES = \
	libcalendarapplet.la

libcalendarapplet_la_SOURCES = \
	CalendarApplet.vala

libcalendarapplet_la_CFLAGS = \
	$(BUDGIE_PLUGIN_CFLAGS)

libcalendarapplet_la_LIBADD = \
	$(BUDGIE_PLUGIN_LIBS)

libcalendarapplet_la_LDFLAGS = \
	-module \
	-avoid-version \
	-shared \
	$(AM_LDFLAGS)

libcalendarapplet_la_VALAFLAGS = \
	--pkg budgie-1.0

calendarapplet_DATA = \
	CalendarApplet.plugin

EXTRA_DIST = \
	CalendarApplet.plugin
