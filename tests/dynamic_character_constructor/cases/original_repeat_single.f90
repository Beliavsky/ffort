module original_m
implicit none
contains
pure function repeat_char(n,xx) result(yy)
! repeat 1-D array of character variables with xx repeated n times
integer          , intent(in) :: n
character (len=*), intent(in) :: xx
character (len=len(xx))       :: yy(n)
integer                       :: i
yy = (/(xx,i=1,n)/)
end function repeat_char
subroutine check(x,n)
character(*),intent(in)::x
integer,intent(in)::n
character(len=len(x))::v(max(0,n))
v=repeat_char(n,x)
if(size(v)/=max(0,n).or.len(v)/=len(x))stop 1
if(any(v/=x))stop 2
write(*,"(i0,1x,i0)")size(v),len(v)
write(*,"(*(a))")v
end subroutine
end module
program p
use original_m
implicit none
call check('Z',1)
end program
