program test
implicit none
integer::n
n=0
call cpu_time(n)
if(n/=37)stop 1
print *,"PASS"
contains
subroutine cpu_time(n)
integer,intent(out)::n
n=37
end subroutine
end program
