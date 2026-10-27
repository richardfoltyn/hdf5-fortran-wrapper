program test_existence
    !* Distinguish absent links from lookup errors and dataset-open failures.
    use, intrinsic :: iso_fortran_env, only: real64
    use hdf5
    use hdf5_wrapper
    use test_support
    implicit none

    integer (hid_t) :: file_id, group_id
    integer :: status
    integer (size_t) :: baseline, count
    logical :: exists, flag
    real (real64) :: value

    call create_fixture (file_id)
    call h5gcreate_f (file_id, 'parent', group_id, status)
    call check (status == 0, 'create parent group')
    call h5gclose_f (group_id, status)
    call check (status == 0, 'close parent group')
    call h5lcreate_soft_f ('missing_target', file_id, 'dangling', status)
    call check (status == 0, 'create dangling soft link')
    call h5eset_auto_f (0, status)
    call check (status == 0, 'disable expected HDF5 error printing')
    call h5fget_obj_count_f (int(H5F_OBJ_ALL_F, hid_t), H5F_OBJ_ALL_F, baseline, status)
    call check (status == 0, 'count initial HDF5 objects')

    call h5lexists_f (file_id, 'missing', exists, status)
    call check (status == 0, 'missing leaf lookup succeeds')
    call check (.not. exists, 'missing leaf is absent')
    call check_loads (file_id, 'missing', STATUS_OK, .true.)
    call check_loads (file_id, 'missing', STATUS_FAILURE, .false.)
    call check_loads (file_id, 'missing', STATUS_FAILURE)

    call h5lexists_f (file_id, 'parent/missing', exists, status)
    call check (status == 0, 'nested missing leaf lookup succeeds')
    call check (.not. exists, 'nested missing leaf is absent')
    call check_loads (file_id, 'parent/missing', STATUS_OK, .true.)
    call check_loads (file_id, 'parent/missing', STATUS_FAILURE, .false.)
    call check_loads (file_id, 'parent/missing', STATUS_FAILURE)

    ! An absent intermediate group makes HDF5 traversal fail, unlike a missing leaf.
    call h5lexists_f (file_id, 'missing_parent/data', exists, status)
    call check (status < 0, 'missing parent produces a lookup error')
    call check_loads (file_id, 'missing_parent/data', STATUS_FAILURE, .true.)
    call check_loads (file_id, 'missing_parent/data', STATUS_FAILURE, .false.)
    call check_loads (file_id, 'missing_parent/data', STATUS_FAILURE)
    call check_loads (-1_hid_t, 'data', STATUS_FAILURE, .true.)
    call check_loads (-1_hid_t, 'data', STATUS_FAILURE, .false.)
    call check_loads (-1_hid_t, 'data', STATUS_FAILURE)

    ! These links exist, but neither can be opened as a dataset.
    call h5lexists_f (file_id, 'parent', exists, status)
    call check (status == 0, 'group lookup succeeds')
    call check (exists, 'group link exists')
    call check_loads (file_id, 'parent', STATUS_FAILURE, .true.)
    call check_loads (file_id, 'parent', STATUS_FAILURE)
    call h5lexists_f (file_id, 'dangling', exists, status)
    call check (status == 0, 'dangling link lookup succeeds')
    call check (exists, 'dangling link exists')
    call check_loads (file_id, 'dangling', STATUS_FAILURE, .true.)
    call check_loads (file_id, 'dangling', STATUS_FAILURE)

    call hdf5_store (-1_hid_t, 'data', 1.0_real64, status=status)
    call check (status == STATUS_FAILURE, 'store with invalid location fails')
    call hdf5_store (file_id, 'missing_parent/data', 1.0_real64, status=status)
    call check (status == STATUS_FAILURE, 'store with missing parent fails')
    call hdf5_store (file_id, 'parent', 1.0_real64, status=status)
    call check (status == STATUS_FAILURE, 'store to group fails')

    call hdf5_store (file_id, 'parent/value', 2.5_real64, status=status)
    call check (status == STATUS_OK, 'create dataset under existing parent')
    call hdf5_store (file_id, 'parent/value', 3.5_real64, status=status)
    call check (status == STATUS_OK, 'overwrite existing dataset')
    call hdf5_load (file_id, 'parent/value', value, ignore_missing=.true., status=status)
    call check (status == STATUS_OK, 'load present numeric scalar with ignore enabled')
    call check (value == 3.5_real64, 'updated numeric scalar value')
    call hdf5_store (file_id, 'parent/flag', .true., status=status)
    call check (status == STATUS_OK, 'store logical scalar')
    call hdf5_load (file_id, 'parent/flag', flag, ignore_missing=.true., status=status)
    call check (status == STATUS_OK, 'load present logical scalar with ignore enabled')
    call check (flag, 'logical scalar value')

    call h5fget_obj_count_f (int(H5F_OBJ_ALL_F, hid_t), H5F_OBJ_ALL_F, count, status)
    call check (status == 0, 'count HDF5 objects after lookups')
    call check (count == baseline, 'lookup paths release acquired objects')
    call remove_fixture (file_id)

contains

subroutine check_loads (loc_id, name, expected_status, ignore_missing)
    !* Exercise every existence-check implementation through the public loaders.
    integer (hid_t), intent(in) :: loc_id
        !* Parent location, possibly invalid.
    character (*), intent(in) :: name
        !* Absent or non-dataset path to load.
    integer, intent(in) :: expected_status
        !* Expected wrapper status.
    logical, intent(in), optional :: ignore_missing
        !* Forwarded unchanged, including its absence, to each loader.

    integer :: load_status
    logical :: logical_value
    real (real64) :: scalar, vector(1)
    real (real64), allocatable :: arr1(:), arr2(:,:), arr3(:,:,:), arr4(:,:,:,:)
    real (real64), allocatable :: arr5(:,:,:,:,:), arr6(:,:,:,:,:,:), arr7(:,:,:,:,:,:,:)

    ! Do not inspect undefined destinations after a skipped or failed read.
    call hdf5_load (loc_id, name, scalar, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': numeric scalar lookup status')
    call hdf5_load (loc_id, name, vector, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': numeric array lookup status')
    call hdf5_load (loc_id, name, logical_value, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': logical scalar lookup status')
    call hdf5_load_alloc (loc_id, name, arr1, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-one allocation lookup status')
    call hdf5_load_alloc (loc_id, name, arr2, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-two allocation lookup status')
    call hdf5_load_alloc (loc_id, name, arr3, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-three allocation lookup status')
    call hdf5_load_alloc (loc_id, name, arr4, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-four allocation lookup status')
    call hdf5_load_alloc (loc_id, name, arr5, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-five allocation lookup status')
    call hdf5_load_alloc (loc_id, name, arr6, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-six allocation lookup status')
    call hdf5_load_alloc (loc_id, name, arr7, ignore_missing, load_status)
    call check (load_status == expected_status, name // ': rank-seven allocation lookup status')
end subroutine

end program
