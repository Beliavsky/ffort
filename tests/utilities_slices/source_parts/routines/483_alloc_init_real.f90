subroutine alloc_init_real(n,xinit,xx)
integer      , intent(in)               :: n
real(kind=dp), intent(in)               :: xinit
real(kind=dp), intent(out), allocatable :: xx(:)
allocate (xx(n))
xx = xinit
end subroutine alloc_init_real
!
