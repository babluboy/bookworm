# the name of the project
project (bookworm)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/bookworm")

set (EXEC_NAME "bookworm")
set (RELEASE_NAME "bookworm v0.5")
set (VERSION "0.5")
set (VERSION_INFO "Bookworm - An eBook Reader")

# Some definitions
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

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
)

include (GSettings)
add_schema ("schemas/com.github.babluboy.bookworm.gschema.xml")

# custom command to update pot template files
set (_pot_file po/${PROJECT_NAME}.pot)
add_custom_command (OUTPUT ${_pot_file}
    COMMAND xgettext --language=C --keyword=_ --escape --sort-output -o po/bookworm.pot src/constants.vala
    DEPENDS ${SOURCE_LIST}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Extract translatable messages to ${_pot_file}")

add_custom_target (pot_file ALL DEPENDS ${_pot_file})

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED
                  gtk+-3.0
                  gee-0.8
                  granite>=0.3.0
                  webkit2gtk-4.0
                  sqlite3>=3.5.9
                 )

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

# files we want to compile
include(ValaPrecompile)

set (BASIC_VALAC_OPTIONS
   -g
   --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
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

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    gee-0.8
    granite>=0.3.0
    webkit2gtk-4.0
    sqlite3
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# set linking libraries
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install bookworm app icons in generic folder - /usr/share/icons/hicolor
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm.png DESTINATION share/icons/hicolor/16x16/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm.png DESTINATION share/icons/hicolor/24x24/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/32/bookworm.png DESTINATION share/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/bookworm.png DESTINATION share/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/64/bookworm.png DESTINATION share/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/128/bookworm.png DESTINATION share/icons/hicolor/128x128/apps)
#install bookworm specific icons in application specific folder - /usr/share/bookworm
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-go-next.svg DESTINATION share/bookworm/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-go-previous.svg DESTINATION share/bookworm/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-list-add.svg DESTINATION share/bookworm/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-list-remove.svg DESTINATION share/bookworm/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-view-grid-symbolic.svg DESTINATION share/bookworm/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-view-list-symbolic.png DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-bookmark-inactive.png DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-bookmark-active.png DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-selection-checked.svg DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-selection-option.svg DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-selection.svg DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-open-menu.svg DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-profile-day.png DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm-profile-night.png DESTINATION share/bookworm/icons/hicolor/24x24/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/bookworm-placeholder-cover.png DESTINATION share/bookworm/icons/hicolor/256x256/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/bookworm-default-cover-1.png DESTINATION share/bookworm/icons/hicolor/256x256/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/bookworm-default-cover-2.png DESTINATION share/bookworm/icons/hicolor/256x256/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/bookworm-default-cover-3.png DESTINATION share/bookworm/icons/hicolor/256x256/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/bookworm-default-cover-4.png DESTINATION share/bookworm/icons/hicolor/256x256/apps/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/bookworm-default-cover-5.png DESTINATION share/bookworm/icons/hicolor/256x256/apps/)

# install app specific desktop, appdata and css files
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.babluboy.bookworm.desktop DESTINATION ${DATADIR}/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.babluboy.bookworm.appdata.xml DESTINATION ${DATADIR}/appdata)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.babluboy.bookworm.app.css DESTINATION ${DATADIR}/bookworm)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/bookworm.contract DESTINATION share/contractor)
