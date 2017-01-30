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
set (RELEASE_NAME "bookworm v0.1")
set (VERSION "0.1")
set (VERSION_INFO "Bookworm - An eBook Reader")

# Some definitions
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# define variable for sources
set (SOURCE_LIST
    src/bookworm.vala
    src/utils.vala
    src/constants.vala
    src/ePubReader.vala
)

# custom command to update pot template files
set (_pot_file po/${PROJECT_NAME}.pot)
add_custom_command (OUTPUT ${_pot_file}
    COMMAND xgettext --language=C --keyword=_ --escape --sort-output -o po/bookworm.pot src/bookworm.vala
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
    src/bookworm.vala
    src/utils.vala
    src/constants.vala
    src/ePubReader.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    gee-0.8
    granite>=0.3.0
    webkit2gtk-4.0
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# set linking libraries
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install bookworm app icons
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm.png DESTINATION share/icons/hicolor/16x16/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/bookworm.png DESTINATION share/icons/hicolor/24x24/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/32/bookworm.png DESTINATION share/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/bookworm.png DESTINATION share/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/64/bookworm.png DESTINATION share/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/128/bookworm.png DESTINATION share/icons/hicolor/128x128/apps)
#install bookworm application specific icons
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-go-next.svg DESTINATION share/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-go-previous.svg DESTINATION share/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-view-list-symbolic.svg DESTINATION share/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-list-add.svg DESTINATION share/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-list-remove.svg DESTINATION share/icons/hicolor/16x16/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/bookworm-view-grid-symbolic.svg DESTINATION share/icons/hicolor/16x16/actions)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/bookworm.desktop DESTINATION ${DATADIR}/applications/)
