################################################################################
# Set additional Fortran compiler FLAGS

unset(_FFLAGS)
unset(_FFLAGS_DEBUG)

if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    # explicitly add -cpp to run C preprocessor if required
    set(GNU_WARN -Wall -Wextra -Wimplicit-interface -Wimplicit-procedure 
        -Warray-temporaries -Wrealloc-lhs -pedantic -Wno-compare-reals 
        -Wno-unused-dummy-argument)
    set(_FFLAGS ${GNU_WARN} -fimplicit-none)
    set(_FFLAGS_DEBUG -O0 -ggdb3)
elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel(LLVM)?")
    if (WIN32)
        set(_FFLAGS /warn:all,nounused)
    else ()
        set(_FFLAGS -warn all,nounused)
    endif (WIN32)
endif ()

################################################################################
# Build target

# Update version include file
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/include/h5fw_version.f90.in
    ${CMAKE_BINARY_DIR}/h5fw_version.f90
)

add_library(${LIBRARY_NAME} hdf5_wrapper.F90)

target_include_directories(${LIBRARY_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_BINARY_DIR}
    PUBLIC
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${H5FW_INSTALL_DIR}>
)

target_link_libraries(${LIBRARY_NAME} PRIVATE
    hdf5::hdf5_fortran
)

target_compile_options(${LIBRARY_NAME}
    PRIVATE
    ${_FFLAGS}
    $<$<CONFIG:Debug>:${_FFLAGS_DEBUG}>
)