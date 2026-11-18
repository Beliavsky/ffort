module clocks
implicit none
contains
subroutine outer()
integer::c,r,m
real::t
call inner()
if(r<0.or.m<0)stop 1
contains
subroutine inner()
call system_clock(c,r,m)
call cpu_time(t)
end subroutine
end subroutine
end module
program test
use clocks
call outer()
print *,"PASS"
end program
