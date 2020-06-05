project('bitmap_test', ['c', 'vala'], 
          version: '0.1.0',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

dependencies = []

dep_glib = dependency ('glib-2.0', required: true)
dep_gobject = dependency ('gobject-2.0', required: true)

dependencies += [dep_glib, dep_gobject]

subdir('src')

executable ('main', source_files, dependencies: dependencies)
