################################################################################
# Set additional Fortran compiler FLAGS

unset(_FFLAGS)
unset(_FFLAGS_Debug)

if (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    # explicitly add -cpp to run C preprocessor if required
    set(GNU_WARN -Wall -Wextra -Wimplicit-interface -Wimplicit-procedure 
        -Warray-temporaries -Wrealloc-lhs -pedantic -Wno-compare-reals 
        -Wno-unused-dummy-argument)
    set(_FFLAGS ${GNU_WARN} -std=f2018 -fimplicit-none)
    set(_FFLAGS_Debug -fcheck=all -O0 -ggdb3)
elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel(LLVM)?")
    if (WIN32)
        set(_FFLAGS /warn:all,nounused /standard-semantics /stand:f18 /auto /assume:nostd_mod_proc_name)
        set(_FFLAGS_debug /check:all /check:arg_temp_created)
        # Disable seriously annoying warning that ifort is deprecated
        if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
            set(_FFLAGS ${_FFLAGS} /Qdiag-disable:10448)
        endif ()
    else ()
        set(_FFLAGS -warn all,nounused -standard-semantics -std18 -auto -assume nostd_mod_proc_name)
        set(_FFLAGS_debug -check all)
        # Disable seriously annoying warning that ifort is deprecated
        if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
            set(_FFLAGS ${_FFLAGS} -diag-disable=10448)
        endif ()
    endif (WIN32)
endif ()

if (_FFLAGS)
    message(STATUS "Fortran compiler flags: ${_FFLAGS}")
endif ()

# Make sure build type is upper case, otherwise the wrong flags will be shown
if (_FFLAGS_${CMAKE_BUILD_TYPE})
    message(STATUS "Additional Fortran compiler flags for ${CMAKE_BUILD_TYPE}: ${_FFLAGS_${CMAKE_BUILD_TYPE}}")
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

target_link_libraries(${LIBRARY_NAME} PUBLIC
    hdf5::hdf5_fortran
)

target_compile_options(${LIBRARY_NAME}
    PRIVATE
    ${_FFLAGS}
    $<$<CONFIG:Debug>:${_FFLAGS_Debug}>
)