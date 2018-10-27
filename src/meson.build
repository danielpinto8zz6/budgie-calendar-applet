gnome = import('gnome')

LOCALE_DIR = join_paths(get_option('prefix'), get_option('localedir'))

data_dir = join_paths(meson.source_root(), 'data')
vapi_dir = join_paths(meson.source_root(), 'vapi')

conf_data = configuration_data()
conf_data.set('PACKAGE_NAME', meson.project_name())
conf_data.set('LOCALE_DIR', LOCALE_DIR)
configure_file(input: 'config.h.in', output: 'config.h', configuration: conf_data)

bha_sources = ['CalendarApplet.vala',
               'CalendarAppletSettings.vala']

bha_deps = [dependency('gtk+-3.0', version: '>=3.18'),
            dependency('budgie-1.0', version: '>=2')]

bha_vala_args = ['--pkg=config',
                 '--vapidir=' + vapi_dir]

bha_c_args = ['-include', 'config.h']

shared_library('calendarapplet', bha_sources,
               dependencies: bha_deps,
               vala_args: bha_vala_args,
               c_args: bha_c_args,
               install: true,
               install_dir: lib_install_dir)
