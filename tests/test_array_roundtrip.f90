program test_array_roundtrip
    !* Verify array ordering, dimension queries, and logical conversion.
    use, intrinsic :: iso_fortran_env, only: real64, int32, int64
    use hdf5_wrapper
    use hdf5, only: hid_t
    use test_support
    implicit none

    integer (hid_t) :: file_id
    integer :: status, rank
    integer (int32) :: dims32(2)
    integer (int64) :: dims64(2)
    real (real64), parameter :: EXPECTED(2,3) = &
        reshape ([1.0_real64, -2.0_real64, 3.5_real64, 4.0_real64, 0.0_real64, 6.0_real64], [2,3])
    logical, parameter :: FLAGS(4) = [.true., .false., .false., .true.]
    real (real64) :: values(2,3)
    logical :: flags_read(4), cube(2,1,2)

    call create_fixture (file_id)
    call hdf5_store (file_id, 'matrix', EXPECTED, status=status)
    call check (status == STATUS_OK, 'store real64 matrix')
    call hdf5_store (file_id, 'flags', FLAGS, status=status)
    call check (status == STATUS_OK, 'store logical vector')
    cube = reshape (FLAGS, shape(cube))
    call hdf5_store (file_id, 'cube', cube, status=status)
    call check (status == STATUS_OK, 'store logical cube')
    call reopen_fixture (file_id)

    call hdf5_dims (file_id, 'matrix', dims32, rank, status)
    call check (status == STATUS_OK, 'query int32 dimensions')
    call check (rank == 2, 'matrix rank')
    call check (all(dims32 == [2_int32, 3_int32]), 'int32 matrix dimensions')
    call hdf5_dims (file_id, 'matrix', dims64, status=status)
    call check (status == STATUS_OK, 'query int64 dimensions')
    call check (all(dims64 == [2_int64, 3_int64]), 'int64 matrix dimensions')

    values = -99.0_real64
    call hdf5_load (file_id, 'matrix', values, status=status)
    call check (status == STATUS_OK, 'load real64 matrix')
    call check (all(values == EXPECTED), 'matrix values and ordering')
    flags_read = .not. FLAGS
    call hdf5_load (file_id, 'flags', flags_read, status=status)
    call check (status == STATUS_OK, 'load logical vector')
    call check (all(flags_read .eqv. FLAGS), 'logical vector values')
    cube = .not. reshape (FLAGS, shape(cube))
    call hdf5_load (file_id, 'cube', cube, status=status)
    call check (status == STATUS_OK, 'load logical cube')
    call check (all(reshape(cube, [4]) .eqv. FLAGS), 'logical cube values')
    call remove_fixture (file_id)
end program
