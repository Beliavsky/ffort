module clocks
implicit none
integer:: c,r,m
real(8)::t
contains
subroutine q()
call system_clock(c,r,m)
call cpu_time(t)
end subroutine
end module
program test
use clocks
call q()
if(r<0.or.m<0)stop 1
print *,"PASS"
end program
