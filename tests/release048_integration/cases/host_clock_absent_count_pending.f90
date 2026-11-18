module m
implicit none
contains
subroutine sample(c,r,m)
integer(8),intent(out),optional::c
integer(8),intent(out)::r,m
call system_clock(count=c,count_rate=r,count_max=m)
end subroutine
end module
program p
use m
implicit none
integer(8)::r,mx
character(:),allocatable::s,c(:)
s='ABCD'
c=[s]
write(*,'(a,t2,z2.2)',advance='no')c,ior(8,7)
call sample(r=r,m=mx)
if(r==0)then
 if(mx/=0)stop 1
else
 if(r<0.or.mx<0)stop 2
end if
write(*,'(a)')'!'
end program
