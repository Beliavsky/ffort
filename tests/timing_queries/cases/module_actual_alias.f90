module m
integer::n
contains
subroutine q(c)
integer,intent(out)::c
call system_clock(c,n)
end subroutine
end module
program test
use m
call q(n)
end program
