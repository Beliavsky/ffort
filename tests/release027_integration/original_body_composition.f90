module utility_combined
implicit none
contains
elemental function strip(xx,xchar) result(yy)
! replace trailing characters of xx that equal xchar with a space
character (len=*), intent(in) :: xx
character (len=1), intent(in) :: xchar
character (len=len(xx))       :: yy
integer                       :: i,nlen
yy = xx
nlen = len(xx)
if (nlen < 1) return
do i=nlen,1,-1
   if (yy(i:i) == " ") cycle
   if (yy(i:i) == xchar) then
      yy(i:i) = " "
   else
      return
   end if
end do
end function strip
function quote(text) result(quoted_text)
! return a quoted and trimmed string
character (len=*), intent(in)      :: text
character (len=len_trim(text) + 2) :: quoted_text
quoted_text = "'" // trim(text) // "'"
end function quote
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
end module
program combined
use utility_combined
implicit none
character(8)::x(3),y(3),s
x=[character(8)::' a***','b**','  c']
y=strip(default_character(x),'*')
if(any(len_trim(y)/=[2,1,3])) error stop 1
if(any(index(y,'b')/=[0,1,0])) error stop 2
print '(a)',quote(adjustl(y(1)))
s=default_character_nlen(8,'fallback','  hi***')
s=strip(s,'*')
print '(a)',quote(adjustl(s))
call set_optional_character(s,' xyz**  ')
s=strip(s,'*')
print '(a)',quote(s)
print *,index(s(2:4),'z'),index(s(2:4),'x',back=.true.),len_trim(s(2:))
end program
