subroutine copy_alloc_vec_real(xvec,yvec)
! allocate yvec to the size xvec and copy the contents of xvec to yvec
real(kind=dp), intent(in)               :: xvec(:) ! source vector
real(kind=dp), intent(out), optional, allocatable :: yvec(:) ! output vector
integer                                 :: n
if (.not. present(yvec)) return
n = size(xvec)
allocate (yvec(n))
yvec = xvec
end subroutine copy_alloc_vec_real
!
