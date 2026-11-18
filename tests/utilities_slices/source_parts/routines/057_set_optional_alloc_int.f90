subroutine set_optional_alloc_int(xx,xdef,xopt)
! set xx(:) to xopt(:) if present and xdef(:) if not
integer, intent(out), allocatable :: xx(:)
integer, intent(in)               :: xdef(:)
integer, intent(in) , optional    :: xopt(:)
if (present(xopt)) then
   call set_alloc(xopt,xx)
else
   call set_alloc(xdef,xx)
end if
end subroutine set_optional_alloc_int
!
