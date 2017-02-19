# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.5

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/choyan/Public/bookworm

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/choyan/Public/bookworm/build

# Include any dependencies generated for this target.
include CMakeFiles/bookworm.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/bookworm.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/bookworm.dir/flags.make

src/bookworm.c: bookworm_valac.stamp


src/utils.c: src/bookworm.c
	@$(CMAKE_COMMAND) -E touch_nocreate src/utils.c

src/constants.c: src/bookworm.c
	@$(CMAKE_COMMAND) -E touch_nocreate src/constants.c

src/ePubReader.c: src/bookworm.c
	@$(CMAKE_COMMAND) -E touch_nocreate src/ePubReader.c

src/book.c: src/bookworm.c
	@$(CMAKE_COMMAND) -E touch_nocreate src/book.c

bookworm_valac.stamp: ../src/bookworm.vala
bookworm_valac.stamp: ../src/utils.vala
bookworm_valac.stamp: ../src/constants.vala
bookworm_valac.stamp: ../src/ePubReader.vala
bookworm_valac.stamp: ../src/book.vala
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating src/bookworm.c;src/utils.c;src/constants.c;src/ePubReader.c;src/book.c"
	/usr/bin/valac -C -b /home/choyan/Public/bookworm -d /home/choyan/Public/bookworm/build --pkg=gtk+-3.0 --pkg=gee-0.8 --pkg=granite>=0.3.0 --pkg=webkit2gtk-4.0 --pkg=sqlite3 -g /home/choyan/Public/bookworm/src/bookworm.vala /home/choyan/Public/bookworm/src/utils.vala /home/choyan/Public/bookworm/src/constants.vala /home/choyan/Public/bookworm/src/ePubReader.vala /home/choyan/Public/bookworm/src/book.vala
	touch /home/choyan/Public/bookworm/build/bookworm_valac.stamp

CMakeFiles/bookworm.dir/src/bookworm.c.o: CMakeFiles/bookworm.dir/flags.make
CMakeFiles/bookworm.dir/src/bookworm.c.o: src/bookworm.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/bookworm.dir/src/bookworm.c.o"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/bookworm.dir/src/bookworm.c.o   -c /home/choyan/Public/bookworm/build/src/bookworm.c

CMakeFiles/bookworm.dir/src/bookworm.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/bookworm.dir/src/bookworm.c.i"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/choyan/Public/bookworm/build/src/bookworm.c > CMakeFiles/bookworm.dir/src/bookworm.c.i

CMakeFiles/bookworm.dir/src/bookworm.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/bookworm.dir/src/bookworm.c.s"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/choyan/Public/bookworm/build/src/bookworm.c -o CMakeFiles/bookworm.dir/src/bookworm.c.s

CMakeFiles/bookworm.dir/src/bookworm.c.o.requires:

.PHONY : CMakeFiles/bookworm.dir/src/bookworm.c.o.requires

CMakeFiles/bookworm.dir/src/bookworm.c.o.provides: CMakeFiles/bookworm.dir/src/bookworm.c.o.requires
	$(MAKE) -f CMakeFiles/bookworm.dir/build.make CMakeFiles/bookworm.dir/src/bookworm.c.o.provides.build
.PHONY : CMakeFiles/bookworm.dir/src/bookworm.c.o.provides

CMakeFiles/bookworm.dir/src/bookworm.c.o.provides.build: CMakeFiles/bookworm.dir/src/bookworm.c.o


CMakeFiles/bookworm.dir/src/utils.c.o: CMakeFiles/bookworm.dir/flags.make
CMakeFiles/bookworm.dir/src/utils.c.o: src/utils.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building C object CMakeFiles/bookworm.dir/src/utils.c.o"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/bookworm.dir/src/utils.c.o   -c /home/choyan/Public/bookworm/build/src/utils.c

CMakeFiles/bookworm.dir/src/utils.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/bookworm.dir/src/utils.c.i"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/choyan/Public/bookworm/build/src/utils.c > CMakeFiles/bookworm.dir/src/utils.c.i

CMakeFiles/bookworm.dir/src/utils.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/bookworm.dir/src/utils.c.s"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/choyan/Public/bookworm/build/src/utils.c -o CMakeFiles/bookworm.dir/src/utils.c.s

CMakeFiles/bookworm.dir/src/utils.c.o.requires:

.PHONY : CMakeFiles/bookworm.dir/src/utils.c.o.requires

CMakeFiles/bookworm.dir/src/utils.c.o.provides: CMakeFiles/bookworm.dir/src/utils.c.o.requires
	$(MAKE) -f CMakeFiles/bookworm.dir/build.make CMakeFiles/bookworm.dir/src/utils.c.o.provides.build
.PHONY : CMakeFiles/bookworm.dir/src/utils.c.o.provides

CMakeFiles/bookworm.dir/src/utils.c.o.provides.build: CMakeFiles/bookworm.dir/src/utils.c.o


CMakeFiles/bookworm.dir/src/constants.c.o: CMakeFiles/bookworm.dir/flags.make
CMakeFiles/bookworm.dir/src/constants.c.o: src/constants.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building C object CMakeFiles/bookworm.dir/src/constants.c.o"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/bookworm.dir/src/constants.c.o   -c /home/choyan/Public/bookworm/build/src/constants.c

CMakeFiles/bookworm.dir/src/constants.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/bookworm.dir/src/constants.c.i"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/choyan/Public/bookworm/build/src/constants.c > CMakeFiles/bookworm.dir/src/constants.c.i

CMakeFiles/bookworm.dir/src/constants.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/bookworm.dir/src/constants.c.s"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/choyan/Public/bookworm/build/src/constants.c -o CMakeFiles/bookworm.dir/src/constants.c.s

CMakeFiles/bookworm.dir/src/constants.c.o.requires:

.PHONY : CMakeFiles/bookworm.dir/src/constants.c.o.requires

CMakeFiles/bookworm.dir/src/constants.c.o.provides: CMakeFiles/bookworm.dir/src/constants.c.o.requires
	$(MAKE) -f CMakeFiles/bookworm.dir/build.make CMakeFiles/bookworm.dir/src/constants.c.o.provides.build
.PHONY : CMakeFiles/bookworm.dir/src/constants.c.o.provides

CMakeFiles/bookworm.dir/src/constants.c.o.provides.build: CMakeFiles/bookworm.dir/src/constants.c.o


CMakeFiles/bookworm.dir/src/ePubReader.c.o: CMakeFiles/bookworm.dir/flags.make
CMakeFiles/bookworm.dir/src/ePubReader.c.o: src/ePubReader.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building C object CMakeFiles/bookworm.dir/src/ePubReader.c.o"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/bookworm.dir/src/ePubReader.c.o   -c /home/choyan/Public/bookworm/build/src/ePubReader.c

CMakeFiles/bookworm.dir/src/ePubReader.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/bookworm.dir/src/ePubReader.c.i"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/choyan/Public/bookworm/build/src/ePubReader.c > CMakeFiles/bookworm.dir/src/ePubReader.c.i

CMakeFiles/bookworm.dir/src/ePubReader.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/bookworm.dir/src/ePubReader.c.s"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/choyan/Public/bookworm/build/src/ePubReader.c -o CMakeFiles/bookworm.dir/src/ePubReader.c.s

CMakeFiles/bookworm.dir/src/ePubReader.c.o.requires:

.PHONY : CMakeFiles/bookworm.dir/src/ePubReader.c.o.requires

CMakeFiles/bookworm.dir/src/ePubReader.c.o.provides: CMakeFiles/bookworm.dir/src/ePubReader.c.o.requires
	$(MAKE) -f CMakeFiles/bookworm.dir/build.make CMakeFiles/bookworm.dir/src/ePubReader.c.o.provides.build
.PHONY : CMakeFiles/bookworm.dir/src/ePubReader.c.o.provides

CMakeFiles/bookworm.dir/src/ePubReader.c.o.provides.build: CMakeFiles/bookworm.dir/src/ePubReader.c.o


CMakeFiles/bookworm.dir/src/book.c.o: CMakeFiles/bookworm.dir/flags.make
CMakeFiles/bookworm.dir/src/book.c.o: src/book.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building C object CMakeFiles/bookworm.dir/src/book.c.o"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/bookworm.dir/src/book.c.o   -c /home/choyan/Public/bookworm/build/src/book.c

CMakeFiles/bookworm.dir/src/book.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/bookworm.dir/src/book.c.i"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/choyan/Public/bookworm/build/src/book.c > CMakeFiles/bookworm.dir/src/book.c.i

CMakeFiles/bookworm.dir/src/book.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/bookworm.dir/src/book.c.s"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/choyan/Public/bookworm/build/src/book.c -o CMakeFiles/bookworm.dir/src/book.c.s

CMakeFiles/bookworm.dir/src/book.c.o.requires:

.PHONY : CMakeFiles/bookworm.dir/src/book.c.o.requires

CMakeFiles/bookworm.dir/src/book.c.o.provides: CMakeFiles/bookworm.dir/src/book.c.o.requires
	$(MAKE) -f CMakeFiles/bookworm.dir/build.make CMakeFiles/bookworm.dir/src/book.c.o.provides.build
.PHONY : CMakeFiles/bookworm.dir/src/book.c.o.provides

CMakeFiles/bookworm.dir/src/book.c.o.provides.build: CMakeFiles/bookworm.dir/src/book.c.o


# Object files for target bookworm
bookworm_OBJECTS = \
"CMakeFiles/bookworm.dir/src/bookworm.c.o" \
"CMakeFiles/bookworm.dir/src/utils.c.o" \
"CMakeFiles/bookworm.dir/src/constants.c.o" \
"CMakeFiles/bookworm.dir/src/ePubReader.c.o" \
"CMakeFiles/bookworm.dir/src/book.c.o"

# External object files for target bookworm
bookworm_EXTERNAL_OBJECTS =

bookworm: CMakeFiles/bookworm.dir/src/bookworm.c.o
bookworm: CMakeFiles/bookworm.dir/src/utils.c.o
bookworm: CMakeFiles/bookworm.dir/src/constants.c.o
bookworm: CMakeFiles/bookworm.dir/src/ePubReader.c.o
bookworm: CMakeFiles/bookworm.dir/src/book.c.o
bookworm: CMakeFiles/bookworm.dir/build.make
bookworm: CMakeFiles/bookworm.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/choyan/Public/bookworm/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Linking C executable bookworm"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/bookworm.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/bookworm.dir/build: bookworm

.PHONY : CMakeFiles/bookworm.dir/build

CMakeFiles/bookworm.dir/requires: CMakeFiles/bookworm.dir/src/bookworm.c.o.requires
CMakeFiles/bookworm.dir/requires: CMakeFiles/bookworm.dir/src/utils.c.o.requires
CMakeFiles/bookworm.dir/requires: CMakeFiles/bookworm.dir/src/constants.c.o.requires
CMakeFiles/bookworm.dir/requires: CMakeFiles/bookworm.dir/src/ePubReader.c.o.requires
CMakeFiles/bookworm.dir/requires: CMakeFiles/bookworm.dir/src/book.c.o.requires

.PHONY : CMakeFiles/bookworm.dir/requires

CMakeFiles/bookworm.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/bookworm.dir/cmake_clean.cmake
.PHONY : CMakeFiles/bookworm.dir/clean

CMakeFiles/bookworm.dir/depend: src/bookworm.c
CMakeFiles/bookworm.dir/depend: src/utils.c
CMakeFiles/bookworm.dir/depend: src/constants.c
CMakeFiles/bookworm.dir/depend: src/ePubReader.c
CMakeFiles/bookworm.dir/depend: src/book.c
CMakeFiles/bookworm.dir/depend: bookworm_valac.stamp
	cd /home/choyan/Public/bookworm/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/choyan/Public/bookworm /home/choyan/Public/bookworm /home/choyan/Public/bookworm/build /home/choyan/Public/bookworm/build /home/choyan/Public/bookworm/build/CMakeFiles/bookworm.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/bookworm.dir/depend

