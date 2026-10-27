# Retain the standalone installed-package client example.
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    cmake_minimum_required(VERSION 3.14)
    project(H5FW_client LANGUAGES C Fortran)
    find_package(HDF5 REQUIRED COMPONENTS Fortran)
    find_package(h5fw REQUIRED)
    add_executable(client client.f90)
    target_link_libraries(client h5fw::h5fw hdf5::hdf5_fortran)
    return()
endif ()

# Keep test-only modules outside the library's installed module directory.
set(TEST_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules")
file(MAKE_DIRECTORY "${TEST_MODULE_DIRECTORY}")
add_library(test_support STATIC test_support.f90)
set_target_properties(test_support PROPERTIES
    Fortran_MODULE_DIRECTORY "${TEST_MODULE_DIRECTORY}"
)
target_include_directories(test_support PUBLIC
    "${TEST_MODULE_DIRECTORY}"
    "${CMAKE_Fortran_MODULE_DIRECTORY}"
)
target_link_libraries(test_support PUBLIC h5fw hdf5::hdf5_fortran)

foreach (test_name IN ITEMS scalar_roundtrip array_roundtrip alloc_roundtrip
        dimensions cleanup existence)
    add_executable(test_${test_name} test_${test_name}.f90)
    target_link_libraries(test_${test_name} PRIVATE test_support)
    set(test_directory "${CMAKE_CURRENT_BINARY_DIR}/fixtures/${test_name}")
    file(MAKE_DIRECTORY "${test_directory}")
    add_test(NAME ${test_name} COMMAND test_${test_name})
    set_tests_properties(${test_name} PROPERTIES
        WORKING_DIRECTORY "${test_directory}"
        TIMEOUT 30
    )
endforeach ()
