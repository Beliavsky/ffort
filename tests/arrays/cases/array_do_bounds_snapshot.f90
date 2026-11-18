program probe
implicit none
integer :: limits(3),i,s
limits(1)=1
limits(2)=5
limits(3)=2
s=0
do i=limits(1),limits(2),limits(3)
 s=s+i
 limits(1)=0
 limits(2)=0
 limits(3)=0
end do
print *,s,i,limits(2)
end program probe
