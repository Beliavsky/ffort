program test
implicit none
integer :: c,r,m
call q()
call q(c,r,m)
if(r<0.or.m<0)stop 1
print *,"PASS"
contains
subroutine q(c,r,m)
integer,optional,intent(out)::c,r,m
call system_clock(count=c,count_rate=r,count_max=m)
end subroutine
end program
