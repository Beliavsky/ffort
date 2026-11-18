program p
implicit none
integer::a(-1:4,-2:3),b(3,3),i,j,s(-3:-1)
do j=-2,3
do i=-1,4
a(i,j)=10*j+i
end do
end do
s=[1,0,-1]
b=cshift(a(4:0:-2,3:-1:-2),s(-1:-3:-1),2)
if(any(b/=reshape([-6,32,10,34,12,-10,14,-8,30],[3,3]))) error stop 1
if(lbound(cshift(a,1),1)/=1.or.lbound(cshift(a,1),2)/=1) error stop 2
print *, "PASS"
end program
