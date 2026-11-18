module m
implicit none
contains
subroutine bump(a)
integer,intent(inout)::a(:)
a=a+2
end subroutine
end module
program p
use m
implicit none
integer,save::a(-2:2)=[1,2,3,4,5]
call bump(a(-2:0))
call bump(a(1:2))
print *,a
end program
