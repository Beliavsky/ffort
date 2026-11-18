module m
implicit none
contains
pure subroutine bump(a)
integer,intent(inout)::a(:)
a=a+1
end subroutine
end module
program p
use m
implicit none
integer,save::a(2)=[1,2]
call bump(a)
call bump(a)
print *,a
end program
