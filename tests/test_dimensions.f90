program test_dimensions
    !* Verify dimension-query outputs on success and on recoverable failures.
    use, intrinsic :: iso_fortran_env, only: int32, int64, real64
    use hdf5
    use hdf5_wrapper
    use test_support
    implicit none

    integer (hid_t) :: file_id, group_id
    integer :: status, rank
    integer (int32) :: dims32(3), short32(1), empty32(0)
    integer (int64) :: dims64(3), short64(1), empty64(0)
    real (real64) :: matrix(2,3)

    call create_fixture (file_id)
    matrix = 1.0_real64
    call hdf5_store (file_id, 'matrix', matrix, status=status)
    call check (status == STATUS_OK, 'store dimension-query matrix')
    call hdf5_store (file_id, 'scalar', 1.0_real64, status=status)
    call check (status == STATUS_OK, 'store dimension-query scalar')
    call h5gcreate_f (file_id, 'group', group_id, status)
    call check (status == 0, 'create non-dataset object')
    call h5gclose_f (group_id, status)
    call check (status == 0, 'close non-dataset object')
    call reopen_fixture (file_id)
    call h5eset_auto_f (0, status)
    call check (status == 0, 'disable expected HDF5 error printing')

    call check_failed_query (file_id, 'missing')
    call check_failed_query (-1_hid_t, 'matrix')
    call check_failed_query (file_id, 'group')

    short32 = 99
    rank = 99
    call hdf5_dims (file_id, 'matrix', short32, rank, status)
    call check (status == STATUS_FAILURE, 'short int32 dimension buffer fails')
    call check (all(short32 == -1), 'short int32 buffer sentinel')
    call check (rank == -1, 'short int32 buffer rank sentinel')
    short64 = 99
    rank = 99
    call hdf5_dims (file_id, 'matrix', short64, rank, status)
    call check (status == STATUS_FAILURE, 'short int64 dimension buffer fails')
    call check (all(short64 == -1), 'short int64 buffer sentinel')
    call check (rank == -1, 'short int64 buffer rank sentinel')

    call hdf5_dims (file_id, 'matrix', dims32, rank, status)
    call check (status == STATUS_OK, 'int32 matrix dimensions succeed')
    call check (rank == 2, 'int32 matrix rank')
    call check (all(dims32 == [2_int32, 3_int32, -1_int32]), 'int32 dimensions and unused entry')
    call hdf5_dims (file_id, 'matrix', dims64, rank, status)
    call check (status == STATUS_OK, 'int64 matrix dimensions succeed')
    call check (rank == 2, 'int64 matrix rank')
    call check (all(dims64 == [2_int64, 3_int64, -1_int64]), 'int64 dimensions and unused entry')
    call hdf5_dims (file_id, 'matrix', ndims=rank, status=status)
    call check (status == STATUS_OK, 'rank-only query succeeds')
    call check (rank == 2, 'rank-only matrix result')

    call hdf5_dims (file_id, 'scalar', empty32, rank, status)
    call check (status == STATUS_OK, 'scalar accepts empty int32 buffer')
    call check (rank == 0, 'int32 scalar rank')
    call hdf5_dims (file_id, 'scalar', empty64, rank, status)
    call check (status == STATUS_OK, 'scalar accepts empty int64 buffer')
    call check (rank == 0, 'int64 scalar rank')
    call hdf5_dims (file_id, 'scalar', dims32, status=status)
    call check (status == STATUS_OK, 'scalar with padded int32 buffer')
    call check (all(dims32 == -1), 'scalar int32 padding')
    call hdf5_dims (file_id, 'scalar', dims64, status=status)
    call check (status == STATUS_OK, 'scalar with padded int64 buffer')
    call check (all(dims64 == -1), 'scalar int64 padding')
    call hdf5_dims (file_id, 'scalar', ndims=rank, status=status)
    call check (status == STATUS_OK, 'scalar rank-only query succeeds')
    call check (rank == 0, 'scalar rank-only result')
    call hdf5_dims (file_id, 'matrix', status=status)
    call check (status == STATUS_OK, 'query with only status output')
    call remove_fixture (file_id)

contains

subroutine check_failed_query (loc_id, name)
    !* Both dimension overloads must define all outputs when opening fails.
    integer (hid_t), intent(in) :: loc_id
        !* Parent identifier, possibly invalid.
    character (*), intent(in) :: name
        !* Missing dataset name or the name of a non-dataset object.

    dims32 = 99
    rank = 99
    call hdf5_dims (loc_id, name, dims32, rank, status)
    call check (status == STATUS_FAILURE, name // ': int32 query fails')
    call check (all(dims32 == -1), name // ': int32 failure dimensions')
    call check (rank == -1, name // ': int32 failure rank')
    dims64 = 99
    rank = 99
    call hdf5_dims (loc_id, name, dims64, rank, status)
    call check (status == STATUS_FAILURE, name // ': int64 query fails')
    call check (all(dims64 == -1), name // ': int64 failure dimensions')
    call check (rank == -1, name // ': int64 failure rank')
    call hdf5_dims (loc_id, name, ndims=rank, status=status)
    call check (status == STATUS_FAILURE, name // ': rank-only query fails')
    call check (rank == -1, name // ': rank-only failure sentinel')

    ! The output contract also holds when the caller omits optional status.
    dims32 = 99
    call hdf5_dims (loc_id, name, dims32)
    call check (all(dims32 == -1), name // ': int32 failure without status')
    dims64 = 99
    call hdf5_dims (loc_id, name, dims64)
    call check (all(dims64 == -1), name // ': int64 failure without status')
end subroutine

end program
