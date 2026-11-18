module original_runtime_formats
implicit none
integer,parameter::dp=kind(0.0d0)
interface set_optional
module procedure set_optional_character
end interface
contains
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

function integer_label(i,fmt_i) result(ilabel)
! return integer labels from i1 to i2 with format fmt_i
integer          , intent(in)           :: i
character (len=*), intent(in), optional :: fmt_i
character (len=20)                      :: ilabel
character (len=20)                      :: fmt_i_
call set_optional(fmt_i_,xdef="(i0)",xopt=fmt_i)
write (ilabel,fmt_i_) i
end function integer_label

elemental function str_real(xx,fmt_real) result(ch)
real(kind=dp), intent(in) :: xx
character (len=*), intent(in), optional :: fmt_real
character (len=20) :: ch
if (present(fmt_real)) then
   write (ch,fmt_real) xx
else
   write (ch,"(f20.4)") xx
end if
ch = adjustl(ch)
end function str_real

pure function str_concat(fmt,str,xx) result(new_str)
character (len=*), intent(in) :: fmt,str
real(kind=dp), intent(in) :: xx(:)
character (len=100) :: new_str
write (new_str,fmt) trim(str),xx
end function str_concat
end module
program p
use original_runtime_formats
implicit none
character(20)::fmt
fmt='(i5.3)'
print '(a,"|")',integer_label(5),integer_label(-42,'(i6.4)'),integer_label(7,fmt)
print '(a,"|")',str_real(1.25d0),str_real(-2.5d0,'(f8.2)')
print '(a,"|")',str_real([1.25d0,-2.5d0],'(f8.2)')
print '(a,"|")',str_concat('(a,2f6.2)','x ',[1.25d0,-2.5d0])
print '(a,"|")',str_concat('(a,*(1x,f5.1))','rows',[1d0,2d0,3d0])
end program
