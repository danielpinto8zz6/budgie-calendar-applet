project('budgie-calendar-applet',
        ['vala', 'c'],
        version: '5.0',
        meson_version: '>=0.40.0',
        license: 'GPL2')

i18n = import('i18n')

lib_install_dir = join_paths(get_option('prefix'), get_option(
    'libdir'), 'budgie-desktop', 'plugins', meson.project_name())

subdir('src')
subdir('data')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')
