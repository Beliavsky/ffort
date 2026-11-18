program test
implicit none
integer::n
n=0
call system_clock(n)
if(n/=37)stop 1
print *,"PASS"
contains
subroutine system_clock(n)
integer,intent(out)::n
n=37
end subroutine
end program
