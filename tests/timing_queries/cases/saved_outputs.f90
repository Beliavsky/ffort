program test
implicit none

call q()
call q()
print *,"PASS"
contains
subroutine q()
integer,save::c=0,r=0,m=0
real,save::t=0
call system_clock(c,r,m)
call cpu_time(t)
if(r<0.or.m<0)stop 1
end subroutine
end program
