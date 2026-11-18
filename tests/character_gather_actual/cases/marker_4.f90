module m
contains
subroutine consume(v)
character(*),intent(in)::v(:)
if(any(v/=["ef","ab","ef"]))error stop "value"
end subroutine
subroutine second(s,v)
character(*),intent(in)::s
character(*),intent(in)::v(:)
call consume(v)
end subroutine
subroutine two(a,v)
character(*),intent(in)::a(:),v(:)
call consume(v)
end subroutine
function first(v) result(answer)
character(*),intent(in)::v(:)
character(2)::answer
answer=v(1)
end function
end module
program main
use m
implicit none
character(2)::x(3)=["ab","cd","ef"]
call consume( &
! grouping after keyword
v = &
 (x([3,1,3])))
end program
