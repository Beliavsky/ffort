program test
implicit none
integer(4) :: c
call system_clock(count=c)
if(c<0.and.c/=-huge(c))stop 1
print *,"PASS"

end program
