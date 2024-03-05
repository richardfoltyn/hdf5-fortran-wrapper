# Build instructions for minimal client application

cmake_minimum_required(VERSION 3.14)

project(H5FW_client LANGUAGES C Fortran)

# set(HDF5_FIND_DEBUG ON)
# set(HDF5_USE_STATIC_LIBRARIES ON)
find_package(HDF5 REQUIRED COMPONENTS Fortran)
find_package(h5fw REQUIRED)

add_executable(client client.f90)
target_link_libraries(client h5fw::h5fw hdf5::hdf5_fortran)

