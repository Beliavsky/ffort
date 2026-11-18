program main
implicit none
character(4)::x
if(default_character('abcd')/='abcd') error stop 1
if(default_character('abcd','xy')/='xy  ') error stop 2
if(default_character_nlen(3,'abcd')/='abc') error stop 3
if(default_character_nlen(3,'abcd','xy')/='xy ') error stop 4
call set_optional_character(x,'abcd')
if(x/='abcd') error stop 5
call set_optional_character(x,'abcd','xy')
if(x/='xy  ') error stop 6
print *, 'PASS'
contains
elemental function default_character(def,opt) result(yy)
! return opt if it is present, otherwise def (character arguments and result)
character (len=*), intent(in)           :: def
character (len=*), intent(in), optional :: opt
character (len=len(def))                :: yy
if (present(opt)) then
   yy = opt
else
   yy = def
end if
end function default_character
function default_character_nlen(nlen,def,opt) result(yy)
! return string of length nlen that is opt if it is present, otherwise def (character arguments and result)
integer          , intent(in)           :: nlen
character (len=*), intent(in)           :: def
character (len=*), intent(in), optional :: opt
character (len=nlen)                    :: yy
if (present(opt)) then
   yy = opt
else
   yy = def
end if
end function default_character_nlen
elemental subroutine set_optional_character(xx,xdef,xopt)
! set xx to (xopt,xdef) if xopt (is,is not) PRESENT
character(len=*), intent(out)          :: xx
character(len=*), intent(in)           :: xdef
character(len=*), intent(in), optional :: xopt
if (present(xopt)) then
   xx = xopt
else
   xx = xdef
end if
end subroutine set_optional_character
end program
