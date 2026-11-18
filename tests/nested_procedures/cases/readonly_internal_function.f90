module m
implicit none
contains
subroutine host(base,answer)
integer,intent(in)::base
integer,intent(out)::answer
answer=twice(3)+twice(4)
contains
integer function twice(x) result(y)
integer,intent(in)::x
y=base+x+x
end function
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(10,answer)
print *,answer
end program
