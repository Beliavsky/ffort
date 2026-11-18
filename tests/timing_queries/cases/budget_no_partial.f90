program test
implicit none
integer::c,r,m
c=7
r=8
m=9
call system_clock(c,r,m)
print *,c,r,m

end program
