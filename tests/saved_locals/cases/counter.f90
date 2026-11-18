module m
implicit none
contains
subroutine count_up()
integer,save::n=0
n=n+1
print *,n
end subroutine
recursive subroutine visit(k)
integer,intent(in)::k
integer::counter=0
counter=counter+1
if(k>0) call visit(k-1)
print *,k,counter
end subroutine
end module
program p
use m
implicit none
call count_up()
call count_up()
call visit(2)
call visit(0)
end program
