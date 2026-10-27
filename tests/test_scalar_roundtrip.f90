program test_scalar_roundtrip
    !* Round-trip every supported scalar kind through a persisted HDF5 file.
    use, intrinsic :: iso_fortran_env, only: real32, real64, int8, int32, int64
    use hdf5_wrapper
    use hdf5, only: hid_t
    use test_support
    implicit none

    integer (hid_t) :: file_id
    integer :: status
    real (real32) :: r32
    real (real64) :: r64
    integer (int8) :: i8
    integer (int32) :: i32
    integer (int64) :: i64
    logical :: flag

    call create_fixture (file_id)
    call hdf5_store (file_id, 'real32', 1.25_real32, status=status)
    call check (status == STATUS_OK, 'store real32 scalar')
    call hdf5_store (file_id, 'real64', -2.5_real64, status=status)
    call check (status == STATUS_OK, 'store real64 scalar')
    call hdf5_store (file_id, 'int8', -12_int8, status=status)
    call check (status == STATUS_OK, 'store int8 scalar')
    call hdf5_store (file_id, 'int32', 123456_int32, status=status)
    call check (status == STATUS_OK, 'store int32 scalar')
    call hdf5_store (file_id, 'int64', 5000000000_int64, status=status)
    call check (status == STATUS_OK, 'store int64 scalar')
    call hdf5_store (file_id, 'true', .true., status=status)
    call check (status == STATUS_OK, 'store true scalar')
    call hdf5_store (file_id, 'false', .false., status=status)
    call check (status == STATUS_OK, 'store false scalar')
    call reopen_fixture (file_id)

    r32 = 0.0_real32
    call hdf5_load (file_id, 'real32', r32, status=status)
    call check (status == STATUS_OK, 'load real32 scalar')
    call check (r32 == 1.25_real32, 'real32 scalar value')
    r64 = 0.0_real64
    call hdf5_load (file_id, 'real64', r64, status=status)
    call check (status == STATUS_OK, 'load real64 scalar')
    call check (r64 == -2.5_real64, 'real64 scalar value')
    i8 = 0_int8
    call hdf5_load (file_id, 'int8', i8, status=status)
    call check (status == STATUS_OK, 'load int8 scalar')
    call check (i8 == -12_int8, 'int8 scalar value')
    i32 = 0_int32
    call hdf5_load (file_id, 'int32', i32, status=status)
    call check (status == STATUS_OK, 'load int32 scalar')
    call check (i32 == 123456_int32, 'int32 scalar value')
    i64 = 0_int64
    call hdf5_load (file_id, 'int64', i64, status=status)
    call check (status == STATUS_OK, 'load int64 scalar')
    call check (i64 == 5000000000_int64, 'int64 scalar value')
    flag = .false.
    call hdf5_load (file_id, 'true', flag, status=status)
    call check (status == STATUS_OK, 'load true scalar')
    call check (flag, 'true scalar value')
    flag = .true.
    call hdf5_load (file_id, 'false', flag, status=status)
    call check (status == STATUS_OK, 'load false scalar')
    call check (.not. flag, 'false scalar value')
    call remove_fixture (file_id)
end program
