program compiler_test

    use, intrinsic :: iso_fortran_env, only: int32
    use hdf5, only: hid_t
    use hdf5_wrapper, only: hdf5_dims

    implicit none

    integer (hid_t) :: loc_id
    integer (int32) :: dims(1)
    integer :: status

    ! Compile and link only: referencing a procedure also checks archive objects.
    loc_id = -1
    call hdf5_dims (loc_id, 'compiler_test', dims=dims, status=status)

end
