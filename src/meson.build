# Replace parameters in source code
conf_data = configuration_data()
conf_data.set('MESON_INSTALL_PREFIX', install_dir)
conf_data.set('MESON_INSTALL_SCRIPTSDIR', scripts_dir)
conf_data.set('MESON_INSTALL_TASKSDIR', tasks_dir)
conf_data.set('MESON_INSTALL_MOBILIBDIR', mobilib_dir)
conf_data.set('MESON_INSTALL_VERSION', version)
constants_config = configure_file(
    input: 'constants.vala.in',
    output: 'constants.vala',
    configuration: conf_data
)
