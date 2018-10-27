plugin_file = i18n.merge_file(
  input: 'com.github.danielpinto8zz6.budgie-calendar-applet.plugin.in',
  output: 'com.github.danielpinto8zz6.budgie-calendar-applet.plugin',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: lib_install_dir
)

plugin_utils = find_program('desktop-file-validate', required: false)
if plugin_utils.found()
  test('Validate plugin file', plugin_utils,
    args: [plugin_file]
  )
endif

appstream_file = i18n.merge_file(
  input: 'com.github.danielpinto8zz6.budgie-calendar-applet.appdata.xml.in',
  output: 'com.github.danielpinto8zz6.budgie-calendar-applet.appdata.xml',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'appdata')
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test('Validate appstream file', appstream_util,
    args: ['validate', appstream_file]
  )
endif

install_data('com.github.danielpinto8zz6.budgie-calendar-applet.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()]
  )
endif