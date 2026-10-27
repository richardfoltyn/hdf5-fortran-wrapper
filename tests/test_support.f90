module test_support
    !* Assertions and file lifecycle shared by the regression tests.
    use, intrinsic :: iso_fortran_env, only: error_unit
    use hdf5
    implicit none
    private
    public :: check, create_fixture, reopen_fixture, remove_fixture

    character (*), parameter :: FIXTURE = 'roundtrip.h5'

contains

subroutine check (condition, message)
    !* Report the failed assertion and terminate with a nonzero exit status.
    logical, intent(in) :: condition
        !* Condition required for the test to pass.
    character (*), intent(in) :: message
        !* Diagnostic identifying the operation or expectation.

    if (.not. condition) then
        write (error_unit, '(a)') 'FAIL: ' // message
        error stop 1
    end if
end subroutine

subroutine create_fixture (file_id)
    !* Create a fresh file in the test's isolated working directory.
    integer (hid_t), intent(out) :: file_id
        !* HDF5 identifier of the newly created file.
    integer :: status

    call h5open_f (status)
    call check (status == 0, 'initialize HDF5')
    call h5fcreate_f (FIXTURE, H5F_ACC_TRUNC_F, file_id, status)
    call check (status == 0, 'create fixture')
end subroutine

subroutine reopen_fixture (file_id)
    !* Close and reopen the fixture to verify persisted data.
    integer (hid_t), intent(inout) :: file_id
        !* File identifier, replaced by the read-only identifier.
    integer :: status

    call h5fclose_f (file_id, status)
    call check (status == 0, 'close fixture after writing')
    call h5fopen_f (FIXTURE, H5F_ACC_RDONLY_F, file_id, status)
    call check (status == 0, 'reopen fixture for reading')
end subroutine

subroutine remove_fixture (file_id)
    !* Close HDF5 and delete the fixture after a successful test.
    integer (hid_t), intent(in) :: file_id
        !* Identifier of the open fixture.
    integer :: status, unit

    call h5fclose_f (file_id, status)
    call check (status == 0, 'close fixture after reading')
    call h5close_f (status)
    call check (status == 0, 'finalize HDF5')
    open (newunit=unit, file=FIXTURE, status='old', iostat=status)
    call check (status == 0, 'open fixture for deletion')
    close (unit, status='delete', iostat=status)
    call check (status == 0, 'delete fixture')
end subroutine

end module
