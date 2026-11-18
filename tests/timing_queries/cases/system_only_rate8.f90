program test
implicit none
integer(8) :: r
call system_clock(count_rate=r)
if(r<0)stop 1
print *,"PASS"

end program
