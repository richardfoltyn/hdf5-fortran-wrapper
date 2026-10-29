################################################################################
# Set additional Fortran compiler FLAGS

set(_FFLAGS "")
set(_FFLAGS_DEBUG "")

if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    set(GNU_WARN -Wall -Wextra -Wimplicit-interface -Wimplicit-procedure 
        -Warray-temporaries -Wrealloc-lhs -pedantic -Wno-compare-reals 
        -Wno-unused-dummy-argument)
    set(_FFLAGS ${GNU_WARN})
    set(_FFLAGS_DEBUG -O0 -ggdb3)
elseif (CMAKE_Fortran_COMPILER_ID MATCHES "^Intel(LLVM)?$")
    if (WIN32)
        set(_FFLAGS /warn:all,nounused)
    else ()
        set(_FFLAGS "SHELL:-warn all,nounused")
    endif (WIN32)
endif ()

################################################################################
# Build target

# Update version include file
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/include/h5fw_version.f90.in"
    "${CMAKE_CURRENT_BINARY_DIR}/h5fw_version.f90"
)

add_library(${LIBRARY_NAME} hdf5_wrapper.F90)
add_library(h5fw::h5fw ALIAS ${LIBRARY_NAME})
h5fw_set_fortran_options(${LIBRARY_NAME})

set(module_directory "${CMAKE_CURRENT_BINARY_DIR}/modules")
set_target_properties(${LIBRARY_NAME} PROPERTIES
    Fortran_MODULE_DIRECTORY "${module_directory}"
)
if (CMAKE_GENERATOR MATCHES "^Visual Studio"
        AND CMAKE_Fortran_COMPILER_ID MATCHES "^Intel(LLVM)?$")
    string(APPEND module_directory "/$<CONFIG>")
endif ()

target_include_directories(${LIBRARY_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_BINARY_DIR}"
    PUBLIC
        "$<BUILD_INTERFACE:${module_directory}>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${H5FW_INSTALL_DIR}>"
)

target_link_libraries(${LIBRARY_NAME} PRIVATE
    hdf5::hdf5_fortran
)

target_compile_options(${LIBRARY_NAME}
    PRIVATE
    ${_FFLAGS}
    "$<$<CONFIG:Debug>:${_FFLAGS_DEBUG}>"
)
