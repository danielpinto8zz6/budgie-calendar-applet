project('com.github.danielpinto8zz6.budgie-calendar-applet',
        ['vala', 'c'],
        version: '5.1',
        meson_version: '>=0.40.0',
        license: 'GPL2')

add_project_arguments([
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
],
    language: 'c',
)

i18n = import('i18n')

lib_install_dir = join_paths(get_option('prefix'), get_option(
    'libdir'), 'budgie-desktop', 'plugins', meson.project_name())

subdir('src')
subdir('data')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')
