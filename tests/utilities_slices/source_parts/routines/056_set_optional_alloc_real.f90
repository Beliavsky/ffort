subroutine set_optional_alloc_real(xx,xdef,xopt)
! set xx(:) to xopt(:) if present and xdef(:) if not
real(kind=dp), intent(out), allocatable :: xx(:)
real(kind=dp), intent(in)               :: xdef(:)
real(kind=dp), intent(in) , optional    :: xopt(:)
if (present(xopt)) then
   call set_alloc(xopt,xx)
else
   call set_alloc(xdef,xx)
end if
end subroutine set_optional_alloc_real
!
