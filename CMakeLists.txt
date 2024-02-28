
cmake_minimum_required(VERSION 3.12)

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

find_package(HDF5 REQUIRED COMPONENTS Fortran)

################################################################################
# Report options and settings

message(STATUS "Building HDF5 Fortran Wrappers version ${H5FW_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

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
# Compiler-specific installation directories

# Allow for installing ifort and gfortran version of libraries side-by-side by
# appending compiler suffix
string(TOLOWER ${CMAKE_Fortran_COMPILER_ID} Fortran_COMPILER_ID)

# Find major compiler version
string(REGEX REPLACE "(^[0-9]+).*" "\\1" Fortran_COMPILER_VERSION_MAJOR
    "${CMAKE_Fortran_COMPILER_VERSION}")

set(Fortran_COMPILER_SUFFIX "${Fortran_COMPILER_ID}-${Fortran_COMPILER_VERSION_MAJOR}")

# Installation directory within <prefix>/lib, <prefix>/include, etc.
# If not defined by -DINSTALL_DIR by the user, create
# version- and compiler-specific directory name.
if (NOT DEFINED INSTALL_DIR)
    set(_version ${H5FW_VERSION_MAJOR}.${H5FW_VERSION_MINOR})
    set(INSTALL_DIR
        "${LIBRARY_NAME}-${_version}-${Fortran_COMPILER_SUFFIX}"
    )
endif()
set(H5FW_INSTALL_DIR "${INSTALL_DIR}")


################################################################################
# Fortran module directory

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/include)

################################################################################
# Universal compiler FLAGS for all targets

unset(_FFLAGS)
unset(_FFLAGS_DEBUG)

if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU" OR MINGW)
    set(_FFLAGS "-std=f2018 -frecursive -fimplicit-none")
    set(_FFLAGS_DEBUG "-fcheck=all")
elseif (CMAKE_Fortran_COMPILER_ID MATCHES "Intel(LLVM)?")
    if (WIN32)
        set(_FFLAGS "/auto /assume:recursion /stand:f18")
        set(_FFLAGS_DEBUG "/check:all")
        # Disable seriously annoying warning that ifort is deprecated
        if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
            set(_FFLAGS "${_FFLAGS} /Qdiag-disable:10448")
        endif ()
    else ()
        set(_FFLAGS "-auto -assume recursion -std18")
        set(_FFLAGS_DEBUG "-check all")
        # Disable seriously annoying warning that ifort is deprecated
        if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
            set(_FFLAGS "${_FFLAGS} -diag-disable=10448")
        endif ()
    endif (WIN32)
endif ()

set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${_FFLAGS}")
set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} ${_FFLAGS_DEBUG}")



################################################################################
# Add targets in src/

add_subdirectory(src)

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
