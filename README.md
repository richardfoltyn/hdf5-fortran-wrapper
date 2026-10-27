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
For example, on Fedora these can be obtained with
```bash
sudo dnf install hdf5 hdf5-devel
```

### Build instructions

Build the repository root out of source with GCC 16 and the system HDF5
(1.14.6 on Fedora). Set the GCC major version in your shell. On Fedora,
this sets the build path; the default compiler must be the matching version.

Bash:
```bash
GCC_VERSION=16
```

Fish:
```fish
set GCC_VERSION 16
```

The remaining commands work in both shells:

```sh
cmake -S "$HOME/repos/hdf5-fortran-wrapper" \
    -B "$HOME/build/gnu/$GCC_VERSION/hdf5-fortran-wrapper" \
    -DCMAKE_C_COMPILER=gcc -DCMAKE_Fortran_COMPILER=gfortran \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DHDF5_ROOT=/usr
cmake --build "$HOME/build/gnu/$GCC_VERSION/hdf5-fortran-wrapper" --parallel 8
cmake --install "$HOME/build/gnu/$GCC_VERSION/hdf5-fortran-wrapper"
```

On Fedora the GNU-16 CMake package is installed under
`~/.local/lib64/h5fw-0.1-gnu-16/cmake/` and modules under
`~/.local/include/h5fw-0.1-gnu-16/`.

## Regression tests

The root CMake build enables CTest tests by default (`BUILD_TESTING=ON`).
Run a diagnostic build with GNU Fortran:

```sh
cmake -S . -B build/debug -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build build/debug --parallel
ctest --test-dir build/debug --output-on-failure --parallel 3
```

The Debug configuration enables GNU Fortran runtime checks (`-fcheck=all`) for
both the wrapper and tests. To also test optimized code, repeat these commands
with `build/release` and `-DCMAKE_BUILD_TYPE=Release`. To build only the library,
configure with `-DBUILD_TESTING=OFF`.

The tests round-trip scalar kinds, numeric and logical arrays, query dimensions,
and load automatically allocated arrays, including repeated loads and rank-seven
data. Each executable uses its own build-tree fixture directory, so tests can
run in parallel. Successful tests delete their HDF5 files; failed tests retain
them for inspection and replace them on the next run. Failed assertions print a
diagnostic and exit with a nonzero status.

The standalone `cmake -S tests` build remains an installed-package client example;
use the repository root to configure the regression suite.

## Usage

To integrate the library in your own CMake project, augment your `CMakeLists.txt`
as follows. See also the minimal client in `tests/client.f90`.
```CMake
cmake_minimum_required(VERSION 3.12)

project(H5FW_client LANGUAGES C Fortran)

# HDF5 library required for linking
find_package(HDF5 REQUIRED COMPONENTS Fortran)

# Locate the library. Configure with -DCMAKE_PREFIX_PATH="$HOME/.local"
# if it was installed under the prefix shown above.
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
