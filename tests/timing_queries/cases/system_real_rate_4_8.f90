program test
implicit none
integer(4) :: c,m
real(8) :: r
call system_clock(count_max=m,count_rate=r,count=c)
if(r==0)then
 if(m/=0.or.c/=-huge(c))stop 1
else
 if(r<0.or.m<0.or.c<0.or.c>m)stop 2
end if
print *,"PASS"

end program
