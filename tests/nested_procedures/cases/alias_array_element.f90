module m
implicit none
contains
subroutine host()
integer::a(3)
a=1
call child(a(2))
contains
subroutine child(x)
integer,intent(inout)::x
x=x+1
a(1)=a(1)+1
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
