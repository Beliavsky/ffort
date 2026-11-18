program test
implicit none
integer::n
n=f()
if(n/=1)stop 1
print *,"PASS"
contains
integer function f()
integer::c
real::t
call system_clock(c)
call cpu_time(t)
f=1
end function
end program
