module m
integer::calls=0
contains
recursive subroutine count_calls(n)
integer,intent(in)::n
calls=calls+1
if(n>0) call count_calls(n-1)
end subroutine
end module
program p
use m
call count_calls(5)
print *,calls
end program
