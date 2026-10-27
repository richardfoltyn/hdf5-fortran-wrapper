program test_cleanup
    !* Repeated successful and failed operations must release acquired objects.
    use, intrinsic :: iso_fortran_env, only: real64, int64
    use, intrinsic :: iso_c_binding, only: c_loc
    use hdf5
    use hdf5_wrapper
    use test_support
    implicit none

    integer (hid_t) :: file_id, group_id
    integer (size_t) :: baseline, count
    integer (int64) :: dims(2)
    integer :: status, iteration, excessive_rank(33)
    real (real64), target :: matrix(2,3)
    real (real64) :: wrong_shape(2,2), vector(6), scalar, string_buffer(1)
    real (real64), allocatable :: allocated_matrix(:,:), wrong_rank(:)

    call create_fixture (file_id)
    call h5gcreate_f (file_id, 'group', group_id, status)
    call check (status == 0, 'create non-dataset object')
    call h5gclose_f (group_id, status)
    call check (status == 0, 'close non-dataset object')
    call h5eset_auto_f (0, status)
    call check (status == 0, 'disable expected HDF5 error printing')

    ! Across all files this count includes transient datatype identifiers too.
    call h5fget_obj_count_f (int(H5F_OBJ_ALL_F, hid_t), H5F_OBJ_ALL_F, baseline, status)
    call check (status == 0, 'count initial open HDF5 objects')
    excessive_rank = 1

    do iteration = 1, 20
        matrix = 2.5_real64
        call hdf5_store (file_id, 'matrix', matrix, status=status)
        call check (status == STATUS_OK, 'store matrix during cleanup test')
        call hdf5_store (file_id, 'scalar', 3.5_real64, status=status)
        call check (status == STATUS_OK, 'store scalar during cleanup test')
        call hdf5_store (file_id, 'string', 'sample', status=status)
        call check (status == STATUS_OK, 'store string during cleanup test')
        call h5fget_obj_count_f (int(H5F_OBJ_ALL_F, hid_t), H5F_OBJ_ALL_F, count, status)
        call check (status == 0, 'count open objects after stores')
        call check (count == baseline, 'stores leaked HDF5 objects')
        call hdf5_store (file_id, 'group', matrix, status=status)
        call check (status == STATUS_FAILURE, 'store to group fails')
        call hdf5_store (file_id, 'group', 'sample', status=status)
        call check (status == STATUS_FAILURE, 'string store to group fails')
        call hdf5_store (file_id, 'empty_string', '', status=status)
        call check (status == STATUS_FAILURE, 'zero-length string datatype fails')
        ! HDF5 supports at most 32 dimensions; failure occurs before dataset creation.
        call hdf5_store (file_id, 'excessive_rank', c_loc(matrix), excessive_rank, &
            H5T_IEEE_F64LE, H5T_NATIVE_DOUBLE, status=status)
        call check (status == STATUS_FAILURE, 'dataspace creation with excessive rank fails')

        call hdf5_load (file_id, 'matrix', matrix, status=status)
        call check (status == STATUS_OK, 'load matrix during cleanup test')
        call check (all(matrix == 2.5_real64), 'matrix values after repeated load')
        call hdf5_load (file_id, 'scalar', scalar, status=status)
        call check (status == STATUS_OK, 'load scalar during cleanup test')
        call check (scalar == 3.5_real64, 'scalar value after repeated load')
        call hdf5_load (file_id, 'missing', scalar, status=status)
        call check (status == STATUS_FAILURE, 'missing scalar load fails')
        call hdf5_load (-1_hid_t, 'matrix', matrix, status=status)
        call check (status == STATUS_FAILURE, 'load with invalid location fails')
        call hdf5_load (file_id, 'group', matrix, status=status)
        call check (status == STATUS_FAILURE, 'load from group fails')
        call hdf5_load (file_id, 'matrix', wrong_shape, status=status)
        call check (status == STATUS_FAILURE, 'shape mismatch fails')
        call hdf5_load (file_id, 'matrix', vector, status=status)
        call check (status == STATUS_FAILURE, 'rank mismatch fails')
        call hdf5_load (file_id, 'string', string_buffer, status=status)
        call check (status == STATUS_FAILURE, 'unsupported datatype conversion fails')

        call hdf5_load_alloc (file_id, 'matrix', allocated_matrix, status=status)
        call check (status == STATUS_OK, 'allocating matrix load succeeds')
        call check (allocated(allocated_matrix), 'matrix allocated during cleanup test')
        call check (all(shape(allocated_matrix) == [2,3]), 'allocated matrix shape')
        call check (all(allocated_matrix == 2.5_real64), 'allocated matrix values')
        call hdf5_load_alloc (file_id, 'matrix', wrong_rank, status=status)
        call check (status == STATUS_FAILURE, 'allocating load with wrong rank fails')
        call hdf5_dims (file_id, 'matrix', dims, status=status)
        call check (status == STATUS_OK, 'dimension query during cleanup test')
        call hdf5_dims (file_id, 'missing', dims, status=status)
        call check (status == STATUS_FAILURE, 'failed dimension query during cleanup test')

        call h5fget_obj_count_f (int(H5F_OBJ_ALL_F, hid_t), H5F_OBJ_ALL_F, count, status)
        call check (status == 0, 'count open objects after operations')
        call check (count == baseline, 'operations leaked HDF5 objects')
    end do

    call remove_fixture (file_id)
end program
