program test
implicit none
integer :: c,r,m
real(8)::t
CALL SYSTEM_CLOCK(CoUnT_MaX=m,CoUnT=c,CoUnT_RaTe=r)
CALL CPU_TIME(TiMe=t)
if(r<0.or.m<0)stop 1
print *,"PASS"

end program
