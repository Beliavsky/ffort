module original_vec_m
implicit none
contains
pure function present_and_false(xx) result(tf)
logical, intent(in), optional :: xx
logical                       :: tf
if (present(xx)) then
   tf = .not. xx
else
   tf = .false.
end if
end function present_and_false
function repeat_char_vec(n,xx,alternate) result(yy)
! repeat 1-D array with xx repeated n times
integer          , intent(in) :: n
character (len=*), intent(in) :: xx(:)
logical          , intent(in), optional :: alternate
character (len=len(xx))       :: yy(n*size(xx))
integer                       :: i,j
if (present_and_false(alternate)) then
   yy = (/((xx(j),i=1,n),j=1,size(xx))/)
else
   yy = (/(xx,i=1,n)/)
end if
end function repeat_char_vec
subroutine check(n,xx)
integer,intent(in)::n
character(*),intent(in)::xx(:)
character(len(xx))::y(n*size(xx))
y=repeat_char_vec(n,xx,.true.)
if(size(y)/=n*size(xx).or.len(y)/=len(xx))stop 1
write(*,"(i0,1x,i0)")size(y),len(y)
write(*,"(*(a))")y
end subroutine
end module
program p
use original_vec_m
implicit none
character(3)::a(2)
a=['a  ',' b ']
call check(2,a)
end program
