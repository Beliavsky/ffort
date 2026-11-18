subroutine alloc_sub_vec_real(xx,n)
! allocate xx to size n
real(kind=dp), intent(out), allocatable :: xx(:)
integer      , intent(in)               :: n
allocate (xx(max(0,n)))
end subroutine alloc_sub_vec_real
!
