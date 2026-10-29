
cmake_minimum_required(VERSION 3.19)

# Default standalone, single-configuration builds to Release without changing
# an enclosing project's cache or an explicitly selected configuration.
get_property(_h5fw_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR
        AND NOT _h5fw_multi_config
        AND NOT DEFINED CMAKE_BUILD_TYPE
        AND NOT DEFINED ENV{CMAKE_BUILD_TYPE})
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build configuration")
endif ()

project(H5FW 
    VERSION 0.1.0 
    LANGUAGES C Fortran
)
set(LIBRARY_NAME h5fw)

################################################################################
# HDF5 library

find_package(HDF5 REQUIRED COMPONENTS Fortran)

################################################################################
# Report options and settings

message(STATUS "Building HDF5 Fortran Wrappers version ${H5FW_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

###############################################################################
# Path suffixes beneath CMAKE_INSTALL_PREFIX

include(GNUInstallDirs)

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
# If not defined by -DINSTALL_DIR_NAME by the user, create
# version- and compiler-specific directory name.
if (NOT DEFINED INSTALL_DIR_NAME)
    set(_version ${H5FW_VERSION_MAJOR}.${H5FW_VERSION_MINOR})
    set(INSTALL_DIR_NAME
        "${LIBRARY_NAME}-${_version}-${Fortran_COMPILER_SUFFIX}"
    )
endif()
set(H5FW_INSTALL_DIR "${INSTALL_DIR_NAME}")


################################################################################
# Common options for the wrapper and its tests; keep them off consumer targets.

function(h5fw_set_fortran_options target)
    set(options "")
    set(debug_options "")
    if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
        set(options -std=f2018 -frecursive -fimplicit-none)
        set(debug_options -fcheck=all)
    elseif (CMAKE_Fortran_COMPILER_ID MATCHES "^Intel(LLVM)?$")
        if (WIN32)
            set(options /auto /assume:recursion /stand:f18)
            set(debug_options /check:all)
            if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
                list(APPEND options /Qdiag-disable:10448)
            endif ()
        else ()
            set(options -auto "SHELL:-assume recursion" -std18)
            set(debug_options "SHELL:-check all")
            if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
                list(APPEND options -diag-disable=10448)
            endif ()
        endif ()
    endif ()
    target_compile_options(${target} PRIVATE
        "$<$<COMPILE_LANGUAGE:Fortran>:${options}>"
        "$<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Debug>>:${debug_options}>"
    )
endfunction()

################################################################################
# Add targets in src/

add_subdirectory(src)

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(tests)
endif ()

################################################################################
# Installation


# Directory that contains installation-specific (config) files
get_filename_component(H5FW_INSTALL_SOURCE_DIR
    "${CMAKE_CURRENT_LIST_DIR}/install"
    ABSOLUTE
)

# Path where CMake config files will be installed
set(H5FW_INSTALL_CONFIG_PATH 
    "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}/cmake"
)

set(H5FW_INSTALL_NAMESPACE ${LIBRARY_NAME})

set(CONFIG_FILE ${LIBRARY_NAME}-config.cmake)
set(CONFIG_VERSION_FILE ${LIBRARY_NAME}-config-version.cmake)
set(TARGETS_FILE ${LIBRARY_NAME}Targets.cmake)

include(CMakePackageConfigHelpers)

# Combine CMake's version/range and architecture checks with the Fortran
# compiler check so incompatible module files can be skipped during discovery.
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/h5fw-basic-version.cmake"
    VERSION "${H5FW_VERSION}"
    COMPATIBILITY SameMajorVersion
)
file(READ "${CMAKE_CURRENT_BINARY_DIR}/h5fw-basic-version.cmake"
    H5FW_BASIC_VERSION_CHECK)
configure_file("${H5FW_INSTALL_SOURCE_DIR}/config-version.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CONFIG_VERSION_FILE}"
    @ONLY
)

configure_package_config_file("${H5FW_INSTALL_SOURCE_DIR}/config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CONFIG_FILE}"
    INSTALL_DESTINATION "${H5FW_INSTALL_CONFIG_PATH}"
)

install(TARGETS ${LIBRARY_NAME} 
    EXPORT ${LIBRARY_NAME}_targets
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}/${H5FW_INSTALL_DIR}"
)

install(EXPORT ${LIBRARY_NAME}_targets
    FILE "${TARGETS_FILE}"
    NAMESPACE ${H5FW_INSTALL_NAMESPACE}::
    DESTINATION "${H5FW_INSTALL_CONFIG_PATH}"
)

# Install only this library's compiler-specific module files.
get_target_property(_h5fw_module_directory ${LIBRARY_NAME} Fortran_MODULE_DIRECTORY)
if (CMAKE_GENERATOR MATCHES "^Visual Studio"
        AND CMAKE_Fortran_COMPILER_ID MATCHES "^Intel(LLVM)?$")
    string(APPEND _h5fw_module_directory "/$<CONFIG>")
endif ()
install(DIRECTORY "${_h5fw_module_directory}/"
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
