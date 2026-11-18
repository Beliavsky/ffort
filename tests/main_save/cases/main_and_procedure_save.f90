module m
implicit none
contains
subroutine bump(a)
integer,intent(inout)::a(:)
integer,save::n=0
n=n+1
a=a+n
end subroutine
end module
program p
use m
implicit none
integer,save::a(2)=[10,20]
call bump(a)
call bump(a)
print *,a
end program
