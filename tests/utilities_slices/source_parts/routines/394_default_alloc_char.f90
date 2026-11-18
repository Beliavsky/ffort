function default_alloc_char(xdef,xx) result(zz)
character (len=*), intent(in) :: xdef(:)
character (len=*), intent(in), optional :: xx(:)
character (len=100), allocatable :: zz(:)
if (present(xx)) then
   call set_alloc(xx,zz)
else
   call set_alloc(xdef,zz)
end if
end function default_alloc_char
!
