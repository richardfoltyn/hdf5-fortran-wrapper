# Retain the standalone installed-package client example.
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    cmake_minimum_required(VERSION 3.19)
    project(H5FW_client LANGUAGES C Fortran)
    find_package(h5fw REQUIRED)
    add_executable(client client.f90)
    target_link_libraries(client PRIVATE h5fw::h5fw)
    return()
endif ()

# Keep test-only modules outside the library's installed module directory.
set(TEST_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules")
file(MAKE_DIRECTORY "${TEST_MODULE_DIRECTORY}")
add_library(test_support STATIC test_support.f90)
h5fw_set_fortran_options(test_support)
set_target_properties(test_support PROPERTIES
    Fortran_MODULE_DIRECTORY "${TEST_MODULE_DIRECTORY}"
)
if (CMAKE_GENERATOR MATCHES "^Visual Studio"
        AND CMAKE_Fortran_COMPILER_ID MATCHES "^Intel(LLVM)?$")
    string(APPEND TEST_MODULE_DIRECTORY "/$<CONFIG>")
endif ()
target_include_directories(test_support PUBLIC
    "${TEST_MODULE_DIRECTORY}"
)
target_link_libraries(test_support PUBLIC h5fw hdf5::hdf5_fortran)

function(add_wrapper_test test_name source)
    add_executable(test_${test_name} "${source}")
    h5fw_set_fortran_options(test_${test_name})
    target_link_libraries(test_${test_name} PRIVATE test_support)
    set(test_directory "${CMAKE_CURRENT_BINARY_DIR}/fixtures/${test_name}")
    file(MAKE_DIRECTORY "${test_directory}")
    add_test(NAME ${test_name} COMMAND test_${test_name})
    set_tests_properties(${test_name} PROPERTIES
        WORKING_DIRECTORY "${test_directory}"
        TIMEOUT 30
    )
endfunction()

foreach (test_name IN ITEMS scalar_roundtrip array_roundtrip alloc_roundtrip
        dimensions cleanup existence)
    add_wrapper_test(${test_name} "${CMAKE_CURRENT_SOURCE_DIR}/test_${test_name}.f90")
endforeach ()

# Run the same fallback contract against every supported type/rank overload.
# Generated sources stay in the build tree; the template is ordinary Fortran
# with preprocessing to omit combinations that the public API does not expose.
foreach (TEST_KIND IN ITEMS real32 real64 int8 int32 int64 logical)
    set(EQUAL "==")
    set(IS_LOGICAL 0)
    if (TEST_KIND MATCHES "^real")
        set(TEST_TYPE "real (${TEST_KIND})")
        set(FALLBACK "-7.0_${TEST_KIND}")
        set(EXPECTED "3.0_${TEST_KIND}")
    elseif (TEST_KIND STREQUAL "logical")
        set(TEST_TYPE "logical")
        set(FALLBACK ".false.")
        set(EXPECTED ".true.")
        set(EQUAL ".eqv.")
        set(IS_LOGICAL 1)
    else ()
        set(TEST_TYPE "integer (${TEST_KIND})")
        set(FALLBACK "-7_${TEST_KIND}")
        set(EXPECTED "3_${TEST_KIND}")
    endif ()

    foreach (TEST_RANK RANGE 0 7)
        set(HAVE_FIXED 1)
        set(HAVE_ALLOC 1)
        if (TEST_RANK EQUAL 0 OR TEST_KIND STREQUAL "int64")
            set(HAVE_ALLOC 0)
        endif ()
        if (IS_LOGICAL AND NOT TEST_RANK EQUAL 0 AND
                NOT TEST_RANK EQUAL 1 AND NOT TEST_RANK EQUAL 3)
            set(HAVE_FIXED 0)
        endif ()

        set(DIMS "")
        set(COLONS ":")
        set(SHAPE "2")
        set(BOUNDS "-1:0")
        set(SMALL_SHAPE "1")
        set(EMPTY_SHAPE "0")
        set(BACKING_SHAPE "4")
        set(SECTION "1:4:2")
        set(OTHER_SECTION "2:4:2")
        if (TEST_RANK GREATER 1)
            foreach (dimension RANGE 2 ${TEST_RANK})
                string(APPEND COLONS ",:")
                string(APPEND SHAPE ",2")
                string(APPEND BOUNDS ",-1:0")
                string(APPEND SMALL_SHAPE ",1")
                string(APPEND EMPTY_SHAPE ",2")
                string(APPEND BACKING_SHAPE ",2")
                string(APPEND SECTION ",:")
                string(APPEND OTHER_SECTION ",:")
            endforeach ()
        endif ()
        if (TEST_RANK GREATER 0)
            set(DIMS "(${SHAPE})")
        endif ()

        set(test_name "fallback_${TEST_KIND}_${TEST_RANK}d")
        configure_file(test_fallback.F90.in "${test_name}.F90" @ONLY)
        add_wrapper_test(${test_name} "${CMAKE_CURRENT_BINARY_DIR}/${test_name}.F90")
    endforeach ()
endforeach ()
