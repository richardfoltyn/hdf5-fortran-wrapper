# HDF5 Fortran Wrapper

This small wrapper implements a simple interface to store and load 
high-dimensional arrays in Fortran. It is easier to use than the low-level API provided
by the official [HDF5](https://portal.hdfgroup.org/) library.

## Examples

### Reading arrays of unknown shape (but known rank)

```fortran
use hdf5_wrapper

integer (hid_t) :: loc_id
    ! Holds the ID of group or location where dataset is stored
integer :: status
real, dimension(:,:,:), allocatable :: arr

! Routine checks the data dimensions and allocates array `arr` as needed.
! Passing the error flag `status` is optional.
call hdf5_load_alloc (loc_id, "data_name", arr, status=status)

! We can also ignore optional datasets that are not present without
! raising an error.
call hdf5_load_alloc (loc_id, "data_name", arr, ignore_missing=.true.)

! Alternatively, ignore the auto-allocation feature and pre-allocate
! the array manually to some known shape.
allocate (arr(10,10,10))
call hdf5_load (loc_id, "data_name", arr)
```

### Storing arrays

```fortran

use hdf5_wrapper

integer (hid_t) :: loc_id
    ! Holds the ID of group or location where dataset is stored
integer :: status
real, dimension(5,5) :: arr
    ! Array containing data

arr = 1

! Store array
call hdf5_store (loc_id, "data_name", arr)

! Optionally, use GZIP compression (if HDF5 was compiled with gzip support).
! Passing the error flag `status` is optional.
call hdf5_store (loc_id, "data_name", arr, deflate=.true., status=status)

```

## Installation

### Dependencies

The library requires the HDF5 development package(s) to be installed. 
For example, on Fedora this these can be obtained with
```bash
sudo dnf install hdf5-devel
```

### Build instructions

The library is built using [CMake](https://cmake.org/) using
something along the lines of
```bash
cd /path/to/hdf5-fortran/wrapper
mkdir build
cd build
cmake ../src
cmake --build .
cmake --install .
```

## Usage

To integrate the library in your own CMake project, augment your `CMakeLists.txt`
as follows. See also the minimal client in `tests/client.f90`.
```CMake
cmake_minimum_required(VERSION 3.12)

project(H5FW_client LANGUAGES C Fortran)

# HDF5 library required for linking
find_package(HDF5 REQUIRED COMPONENTS Fortran)

# Locale the library. You may need to adapt CMAKE_PREFIX_PATH, depending
# on where the library was installed.
find_package(h5fw REQUIRED)

add_executable(client client.f90)
target_link_libraries(client h5fw::h5fw)

```

## Author

Richard Foltyn

## License

This program is free software: you can redistribute it and/or modify it under 
the terms of the GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option) any later 
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY 
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
PARTICULAR PURPOSE. See the GNU General Public License for more details.
