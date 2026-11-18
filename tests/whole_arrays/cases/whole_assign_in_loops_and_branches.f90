program probe
implicit none
integer :: a(3), i
a=0
do i=1,4
if (i<3) then
a=a+i
else
a=a*2
end if
end do
print *, a,i
end program probe
