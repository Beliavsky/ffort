subroutine alloc_sub_vec_int(xx,n)
! allocate xx to size n
integer, intent(out), allocatable :: xx(:)
integer, intent(in)               :: n
allocate (xx(max(0,n)))
end subroutine alloc_sub_vec_int
!
