program p
implicit none
integer(8)::c,r,m
character(:),allocatable::s,a(:)
call system_clock(c,r,m)
if(r==0)then
 if(m/=0.or.c/=-huge(c))stop 1
else
 if(r<0.or.m<0.or.c<0.or.c>m)stop 2
end if
s='CLOCK '
a=[s]
print '(a,z2.2)',a,bit_size(c)
end program
