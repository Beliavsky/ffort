program test
implicit none
integer(4) :: m
call system_clock(count_max=m)
if(m<0)stop 1
print *,"PASS"

end program
