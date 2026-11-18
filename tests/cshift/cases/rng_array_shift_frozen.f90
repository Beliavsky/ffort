program p
implicit none
integer::a(257,4),b(257,4),i,j,s
do j=1,4
do i=1,257
a(i,j)=i
end do
end do
b=cshift(a,draw(),1)
do j=1,4
s=b(1,j)-1
do i=1,257
if(b(i,j)/=modulo(i-1+s,257)+1) error stop 1
end do
end do
print *, "PASS"
contains
function draw() result(r)
integer::r(4),j
real(8)::x(4)
call random_number(x)
do j=1,4
r(j)=int(257d0*x(j))
end do
end function
end program
