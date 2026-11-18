subroutine set_optional_alloc_character(xx,xdef,xopt,n)
! set xx to (xopt,xdef) if xopt (is,is not) PRESENT
character(len=*), intent(out), allocatable :: xx(:)
character(len=*), intent(in)               :: xdef(:)
character(len=*), intent(in) , optional    :: xopt(:)
integer         , intent(out), optional    :: n
if (present(xopt)) then
   call set_alloc(xopt,xx)
else
   call set_alloc(xdef,xx)
end if
if (present(n)) n = size(xx)
end subroutine set_optional_alloc_character
!
