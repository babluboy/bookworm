# Set the name of the application
project (com.github.babluboy.bookworm)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.8)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Set all the data directories
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/bookworm")
set (SCRIPTS_DIR ${PKGDATADIR}/scripts)

# Set the application executable name and version info
set (EXEC_NAME "com.github.babluboy.bookworm")
set (RELEASE_NAME "bookworm v1.1.0")
set (VERSION "1.1.0")
set (VERSION_INFO "Bookworm - An eBook Reader")

# Translation files
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")
add_subdirectory (po)

# Replace parameters in source code
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/src/constants.vala.in" "${CMAKE_SOURCE_DIR}/src/constants.vala" @ONLY)

# define variable for sources
set (SOURCE_LIST
    src/main.vala
    src/bookworm.vala
    src/utils.vala
    src/constants.vala
    src/ePubReader.vala
    src/book.vala
    src/database.vala
    src/settings.vala
    src/bookinfo.vala
    src/headerbar.vala
    src/dialog.vala
    src/window.vala
    src/prefpopover.vala
    src/library.vala
    src/pdfReader.vala
    src/contentHandler.vala
    src/comicsReader.vala
    src/backgroundTasks.vala
    src/mobiReader.vala
    src/shortcuts.vala
    src/xmlHandler.vala
)

include (GSettings)
add_schema ("schemas/com.github.babluboy.bookworm.gschema.xml")

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED
      gtk+-3.0
      gee-0.8
      granite>=0.5
      webkit2gtk-4.0>=2.18.6
      sqlite3>=3.5.9
      poppler-glib
      libxml-2.0
)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES} -lm)
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.36" MINIMUM)

# files we want to compile
include(GResource)
include(ValaPrecompile)

set (BASIC_VALAC_OPTIONS
   -g
   --thread
   --target-glib=2.38
)

set (GLOBAL_VALAC_OPTIONS
  ${BASIC_VALAC_OPTIONS}
)

vala_precompile(VALA_C ${EXEC_NAME}
    src/main.vala
    src/bookworm.vala
    src/utils.vala
    src/constants.vala
    src/ePubReader.vala
    src/book.vala
    src/database.vala
    src/settings.vala
    src/bookinfo.vala
    src/headerbar.vala
    src/dialog.vala
    src/window.vala
    src/prefpopover.vala
    src/library.vala
    src/pdfReader.vala
    src/contentHandler.vala
    src/comicsReader.vala
    src/backgroundTasks.vala
    src/mobiReader.vala
    src/shortcuts.vala
    src/xmlHandler.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    gee-0.8
    granite>=0.5
    webkit2gtk-4.0>=2.18.6
    sqlite3
    poppler-glib
    libxml-2.0
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE data/com.github.babluboy.bookworm.gresource.xml)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C} ${GRESOURCES})

# set linking libraries
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install bookworm app icons in generic folder - /usr/share/icons/hicolor
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/com.github.babluboy.bookworm.svg DESTINATION share/icons/hicolor/16x16/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/com.github.babluboy.bookworm.svg DESTINATION share/icons/hicolor/24x24/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/32/com.github.babluboy.bookworm.svg DESTINATION share/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/com.github.babluboy.bookworm.svg DESTINATION share/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/64/com.github.babluboy.bookworm.svg DESTINATION share/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/128/com.github.babluboy.bookworm.svg DESTINATION share/icons/hicolor/128x128/apps)

# install app specific desktop, appdata and css files
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.babluboy.bookworm.desktop DESTINATION ${DATADIR}/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.babluboy.bookworm.appdata.xml DESTINATION ${DATADIR}/metainfo/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.babluboy.bookworm.contract DESTINATION share/contractor)

# install bookworm scripts in application specific folder - /usr/share/bookworm/scripts
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/com.github.babluboy.bookworm.search.sh PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/tasks)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_dict.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_html.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_index.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_k8proc.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_ncx.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_opf.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_split.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_uncompress.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_unpack.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/scripts/mobi_lib/mobi_utils.py PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE DESTINATION ${SCRIPTS_DIR}/mobi_lib)
