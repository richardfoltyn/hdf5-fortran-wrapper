# Build instructions for minimal client application

cmake_minimum_required(VERSION 3.12)

project(H5FW_client LANGUAGES C Fortran)

find_package(HDF5 REQUIRED COMPONENTS Fortran)
find_package(h5fw REQUIRED)

add_executable(client client.f90)
target_link_libraries(client h5fw::h5fw)

