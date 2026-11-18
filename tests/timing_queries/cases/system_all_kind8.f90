program test
implicit none
integer(8) :: c,r,m
call system_clock(c,r,m)
if (r==0) then
 if (m/=0.or.c/=-huge(c)) stop 1
else
 if (r<0.or.m<0.or.c<0.or.c>m) stop 2
end if
print *,"PASS"

end program
