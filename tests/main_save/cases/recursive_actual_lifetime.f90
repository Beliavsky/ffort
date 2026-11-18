module m
implicit none
contains
recursive subroutine bump(a,n)
integer,intent(inout)::a(:)
integer,intent(in)::n
a=a+1
if(n>0) call bump(a,n-1)
end subroutine
end module
program p
use m
implicit none
integer,save::a(2)=[10,20]
call bump(a,2)
call bump(a,1)
print *,a
end program
