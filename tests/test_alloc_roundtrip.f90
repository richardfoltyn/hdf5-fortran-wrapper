program test_alloc_roundtrip
    !* Verify automatic allocation and repeated loads of present datasets.
    use, intrinsic :: iso_fortran_env, only: real32, int32
    use hdf5_wrapper
    use hdf5, only: hid_t
    use test_support
    implicit none

    integer (hid_t) :: file_id
    integer :: status
    integer (int32), parameter :: EXPECTED(3) = [7_int32, -4_int32, 19_int32]
    integer (int32), allocatable :: values(:)
    real (real32) :: source(2,1,1,1,1,1,2)
    real (real32), allocatable :: tensor(:,:,:,:,:,:,:)
    logical, parameter :: FLAGS(2,2) = reshape ([.true., .false., .false., .true.], [2,2])
    logical, allocatable :: flags_read(:,:)

    source = reshape ([1.0_real32, 2.0_real32, -3.0_real32, 4.0_real32], shape(source))
    call create_fixture (file_id)
    call hdf5_store (file_id, 'vector', EXPECTED, status=status)
    call check (status == STATUS_OK, 'store int32 vector')
    call hdf5_store (file_id, 'tensor', source, status=status)
    call check (status == STATUS_OK, 'store rank-seven tensor')
    ! Logical rank-two storage is not exposed; use the documented 0/1 representation.
    call hdf5_store (file_id, 'flags', merge(1_int32, 0_int32, FLAGS), status=status)
    call check (status == STATUS_OK, 'store encoded logical matrix')
    call reopen_fixture (file_id)

    call hdf5_load_alloc (file_id, 'vector', values, status=status)
    call check (status == STATUS_OK, 'load initially unallocated vector')
    call check (allocated(values), 'vector allocated')
    call check (size(values) == 3, 'vector extent')
    call check (all(values == EXPECTED), 'vector values')
    values = 0_int32
    call hdf5_load_alloc (file_id, 'vector', values, status=status)
    call check (status == STATUS_OK, 'reload same-shape vector')
    call check (allocated(values), 'reloaded vector allocated')
    call check (size(values) == 3, 'reloaded vector extent')
    call check (all(values == EXPECTED), 'same-shape vector replaced')
    deallocate (values)
    allocate (values(1))
    call hdf5_load_alloc (file_id, 'vector', values, status=status)
    call check (status == STATUS_OK, 'load different-shape vector')
    call check (allocated(values), 'resized vector allocated')
    call check (size(values) == 3, 'resized vector extent')
    call check (all(values == EXPECTED), 'resized vector values')

    call hdf5_load_alloc (file_id, 'tensor', tensor, status=status)
    call check (status == STATUS_OK, 'load rank-seven tensor')
    call check (allocated(tensor), 'tensor allocated')
    call check (all(shape(tensor) == shape(source)), 'tensor shape')
    call check (all(tensor == source), 'tensor values and ordering')
    call hdf5_load_alloc (file_id, 'flags', flags_read, status=status)
    call check (status == STATUS_OK, 'load allocatable logical matrix')
    call check (allocated(flags_read), 'logical matrix allocated')
    call check (all(shape(flags_read) == shape(FLAGS)), 'logical matrix shape')
    call check (all(flags_read .eqv. FLAGS), 'logical matrix values')
    call remove_fixture (file_id)
end program
