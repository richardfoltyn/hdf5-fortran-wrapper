
cmake_minimum_required(VERSION 3.10)

project(H5FW 
    VERSION 0.1.0 
    LANGUAGES C Fortran
)
set(LIBRARY_NAME h5fw)

# make sure that the default is a RELEASE
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE Release CACHE STRING
      "Choose the type of build, options are: None Debug Release."
      FORCE)
endif (NOT CMAKE_BUILD_TYPE)

################################################################################
# HDF5 library
#
# We attempt to find HDF5 installation using the following steps:
# 1.    If HDF5_ROOT is specified, try to locate hdf5-config.cmake in the
#       tree beneath the root folder.
# 2.    If no HDF5_ROOT is specified, search for hdf5-config.cmake in
#       default CMAKE search paths.
# 3.    Assume that no hdf5-config.cmake exists and use FindHDF5 that was
#       shipped with CMake.

# HDF5 package names used in variables created by FindHDF5
string(TOUPPER hdf5 HDF5_PACKAGE_NAME)

# Link against shared or static library
set(lib_type "static")
if (NOT HDF5_STATIC)
    set(lib_type "shared")
endif ()

# components to look for (does not include lib type, ie. static of shared)
set(HDF5_FIND_COMPONENTS Fortran C)

# store either -DHDF5_ROOT from command-line or env. variable HDF5_ROOT;
# command-line spec. takes precedence!
set(_hdf5_root "${HDF5_ROOT}")
if (NOT _hdf5_root AND ENV{HDF5_ROOT})
    set(_hdf5_root "$ENV{HDF5_ROOT}")
endif()

# Invoke FIND_PACKAGE in config mode, ie directly including the
# file hdf5-config.cmake that should have been created by the installer.
if (_hdf5_root)
    find_package(HDF5 QUIET NO_MODULE
        COMPONENTS ${HDF5_FIND_COMPONENTS} ${lib_type}
        HINTS ${_hdf5_root}
        PATH_SUFFIXES cmake share/cmake
        NO_DEFAULT_PATH
    )
else()
    find_package(HDF5 QUIET NO_MODULE
        COMPONENTS ${HDF5_FIND_COMPONENTS} ${lib_type}
    )
endif()

if (HDF5_VERSION_STRING)
    # this is usually set in the FindHDF5 file, not in hdf5-config.cmake
    set(HDF5_FOUND TRUE)

    unset(HDF5_LIBRARIES)
    foreach(comp IN LISTS HDF5_FIND_COMPONENTS)
        string(TOUPPER "${HDF5_PACKAGE_NAME}_${comp}_${lib_type}_LIBRARY" comp_lib)
        list(APPEND HDF5_LIBRARIES ${${comp_lib}})
    endforeach()

    list(APPEND HDF5_INCLUDE_DIRS ${HDF5_INCLUDE_DIR_FORTRAN})

    # store version string for further processing below
    set(_hdf_version ${HDF5_VERSION_STRING})
else()
    # Look for HDF5 using whatever came with CMake, most likely some FindHDF5
    # file.
    # Need to set environment variable to communicate desired
    # HDF5 root to FindHDF5 scripts
    set(_defined_hdf5_env FALSE)
    if (NOT ENV{HDF5_ROOT} AND HDF5_ROOT)
        set(_defined_hdf5_env TRUE)
        set(ENV{HDF5_ROOT} ${HDF5_ROOT})
    endif()

    # communicate to FindHDF5 that we want static libraries
    # Note: This defines the variables HDF5_LIBRARIES, HDF5_INCLUDE_DIRS
    # HDF5_Fortran_INCLUDE_DIRS
    set(HDF5_USE_STATIC_LIBRARIES ${HDF5_STATIC})
    find_package(HDF5 REQUIRED COMPONENTS ${HDF5_FIND_COMPONENTS})

    set(HDF5_LIBRARIES ${HDF5_LIBRARIES} ${HDF5_Fortran_LIBRARIES})
    set(HDF5_INCLUDE_DIRS ${HDF5_INCLUDE_DIRS} ${HDF5_Fortran_INCLUDE_DIRS})

    # Append shared/ or static/ to HDF5 include path as this is present
    # on Windows installation but not correctly returned by FindHDF5
    if (WIN32)
        foreach(_lib IN LISTS HDF5_INCLUDE_DIRS)
            list(APPEND HDF5_INCLUDE_DIRS_SUFFIX "${_lib}/${lib_type}")
        endforeach()
        list(APPEND HDF5_INCLUDE_DIRS ${HDF5_INCLUDE_DIRS_SUFFIX})
    endif ()

    # unset HDF5_ROOT if we defined it above to restore environment to
    # its previous state
    if (_defined_hdf5_env)
        unset(ENV{HDF5_ROOT})
    endif()

    set(_hdf_version ${HDF5_VERSION})
endif()

if (_hdf_version)
    if (_hdf_version VERSION_GREATER "1.9.0")
        add_definitions(-D_HDF5_1_10)
    endif()
endif()

if (NOT WIN32)
    find_package(ZLIB REQUIRED)
    list(APPEND HDF5_LIBRARIES ${ZLIB_LIBRARIES})
endif()

################################################################################
# Set additional Fortran compiler FLAGS

unset(_FFLAGS)
unset(_FFLAGS_DEBUG)
unset(_FFLAGS_RELEASE)

if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    # explicitly add -cpp to run C preprocessor if required
    set(GNU_WARN "-Wall -Wextra -Wimplicit-interface -Wimplicit-procedure \
        -Warray-temporaries -Wrealloc-lhs -pedantic -Wno-compare-reals \
        -Wno-unused-dummy-argument")
    set(_FFLAGS "${GNU_WARN} -std=f2018 -fimplicit-none")
    set(_FFLAGS_DEBUG "-fcheck=all -O0 -ggdb3")
elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel(LLVM)?")
    if (WIN32)
        set(_FFLAGS "/warn:all,nounused /standard-semantics /stand:f18 /auto /assume:nostd_mod_proc_name")
        set(_FFLAGS_DEBUG "/check:all /check:arg_temp_created")
        # Disable seriously annoying warning that ifort is deprecated
        if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
            set(_FFLAGS "${_FFLAGS} /Qdiag-disable:10448")
        endif ()
    else ()
        set(_FFLAGS "-warn all,nounused -standard-semantics -std18 -auto -assume nostd_mod_proc_name")
        set(_FFLAGS_DEBUG "-check all")
        # Disable seriously annoying warning that ifort is deprecated
        if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
            set(_FFLAGS "${_FFLAGS} -diag-disable=10448")
        endif ()
    endif (WIN32)
endif ()

# append additional FLAGS to default cmake FLAGS
set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${_FFLAGS}")
set (CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} ${_FFLAGS_DEBUG}")
set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} ${_FFLAGS_RELEASE}")

################################################################################
# Report options and settings

message(STATUS "Building HDF5 Fortran Wrappers version ${H5FW_VERSION}")
message(STATUS "Building against HDF5 ${_hdf_version}")
message(STATUS "HDF5 include path: ${HDF5_INCLUDE_DIRS}")
message(STATUS "HDF5 link path: ${HDF5_LIBRARY_DIRS}")
message(STATUS "HDF5 libraries: ${HDF5_LIBRARIES}")

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Fortran compiler flags: ${CMAKE_Fortran_FLAGS}")
# Make sure build type is upper case, otherwise the wrong flags will be shown
string(TOUPPER "${CMAKE_BUILD_TYPE}" _BUILD_TYPE)
if (CMAKE_Fortran_FLAGS_${_BUILD_TYPE})
    message(STATUS "Additional Fortran compiler flags for ${CMAKE_BUILD_TYPE}: ${CMAKE_Fortran_FLAGS_${_BUILD_TYPE}}")
endif ()

# on Windows, add bin/ directory in HDF5_ROOT that contains debug symbols
if (WIN32 AND EXISTS "${HDF5_ROOT}/bin")
    link_directories(${HDF5_ROOT}/bin)
endif()




###############################################################################
# Path suffixes beneath CMAKE_INSTALL_PREFIX

# if CMAKE_INSTALL_LIBDIR or CMAKE_INSTALL_INCLUDEDIR were specified on the
# command line, use those as prefixes beneath CMAKE_INSTALL_PREFIX where
# library and include files should be placed.

# store values in temporary variables, will be overwritten by GNUInstallDirs
set(_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}")
set(_INSTALL_INCLUDEDDIR "${CMAKE_INSTALL_INCLUDEDIR}")

include(GNUInstallDirs)

# fill in any missing values
if (_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "${_INSTALL_LIBDIR}")
elseif (NOT CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR lib)
endif()

if (_INSTALL_INCLUDEDDIR)
    set(CMAKE_INSTALL_INCLUDEDIR "${_INSTALL_INCLUDEDDIR}")
elseif (NOT CMAKE_INSTALL_INCLUDEDIR)
    set(CMAKE_INSTALL_INCLUDEDIR include)
endif()

################################################################################
# Installation

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/include)

################################################################################
# Build target

set (SOURCE_FILES
    hdf5_wrapper.F90
)

# Update version include file
configure_file(include/h5fw_version.f90.in
    ${CMAKE_BINARY_DIR}/h5fw_version.f90
)

add_library(${LIBRARY_NAME} ${SOURCE_FILES})

target_include_directories(${LIBRARY_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_BINARY_DIR}
    ${HDF5_INCLUDE_DIRS}
)

target_link_libraries(${LIBRARY_NAME} PUBLIC
    ${HDF5_LIBRARIES}
)

################################################################################
# Compiler-specific installation directories

# Allow for installing ifort and gfortran version of libraries side-by-side by
# appending compiler suffix
string(TOLOWER ${CMAKE_Fortran_COMPILER_ID} Fortran_COMPILER_ID)

# Find major compiler version
string(REGEX REPLACE "(^[0-9]+).*" "\\1" Fortran_COMPILER_VERSION_MAJOR
    "${CMAKE_Fortran_COMPILER_VERSION}")

set(Fortran_COMPILER_SUFFIX "${Fortran_COMPILER_ID}-${Fortran_COMPILER_VERSION_MAJOR}")

# Installation directory within <prefix>/lib, <prefix>/include, etc.
# If ont defined by -DINSTALL_DIR by the user, create
# version- and compiler-specific directory name.
if (NOT DEFINED INSTALL_DIR)
    set(_version ${H5FW_VERSION_MAJOR}.${H5FW_VERSION_MINOR})
    set(INSTALL_DIR
        "${LIBRARY_NAME}-${_version}-${Fortran_COMPILER_SUFFIX}"
    )
endif()
set(H5FW_INSTALL_DIR "${INSTALL_DIR}")


################################################################################
# Installation


# Directory that contains installation-specific (config) files
get_filename_component(H5FW_INSTALL_SOURCE_DIR
    "${CMAKE_CURRENT_LIST_DIR}/install"
    ABSOLUTE
)

# Path there cmake config files will be installed
set(H5FW_INSTALL_CONFIG_PATH 
    "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}/cmake"
)

set(H5FW_INSTALL_NAMESPACE ${LIBRARY_NAME})

set(CONFIG_FILE ${LIBRARY_NAME}-config.cmake)
set(CONFIG_VERSION_FILE ${LIBRARY_NAME}-config-version.cmake)
set(TARGETS_FILE ${LIBRARY_NAME}Targets.cmake)

configure_file("${H5FW_INSTALL_SOURCE_DIR}/config-version.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CONFIG_VERSION_FILE}"
    @ONLY
)

include(CMakePackageConfigHelpers)

configure_package_config_file("${H5FW_INSTALL_SOURCE_DIR}/config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CONFIG_FILE}"
    INSTALL_DESTINATION "${H5FW_INSTALL_CONFIG_PATH}"
    PATH_VARS H5FW_INSTALL_CONFIG_PATH
)

# Note: INCLUDES DESTINATION is equivalent to adding
# INTERFACE_INCLUDE_DIRECTORIES property on exported targets.
install(TARGETS ${LIBRARY_NAME} 
    EXPORT ${LIBRARY_NAME}_targets
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}"
    INCLUDES DESTINATION
        "${CMAKE_INSTALL_INCLUDEDIR}/${H5FW_INSTALL_DIR}"
)

install(EXPORT ${LIBRARY_NAME}_targets
    FILE "${TARGETS_FILE}"
    NAMESPACE ${H5FW_INSTALL_NAMESPACE}::
    DESTINATION "${H5FW_INSTALL_CONFIG_PATH}"
)

# install compiler-specific MOD files
install(DIRECTORY "${CMAKE_Fortran_MODULE_DIRECTORY}/"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${H5FW_INSTALL_DIR}"
    COMPONENT devel
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${CONFIG_FILE}"
    "${CMAKE_CURRENT_BINARY_DIR}/${CONFIG_VERSION_FILE}"
    "${H5FW_INSTALL_SOURCE_DIR}/compiler_test.f90"
    DESTINATION "${H5FW_INSTALL_CONFIG_PATH}"
    COMPONENT devel
)
