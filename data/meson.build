datadir = get_option('datadir')

install_data('CalendarApplet.plugin',
    install_dir: LIB_INSTALL_DIR)

install_data('com.github.danielpinto8zz6.budgie-calendar-applet.gschema.xml',
             install_dir: join_paths(datadir, 'glib-2.0' ,'schemas'))
meson.add_install_script('meson_post_install.py')

install_data('com.github.danielpinto8zz6.budgie-calendar-applet.appdata.xml',
             install_dir: join_paths(datadir, 'appdata'))
