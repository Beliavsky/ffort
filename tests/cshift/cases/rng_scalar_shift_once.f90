program p
implicit none
integer::a(257),b(257),i,s
do i=1,257
a(i)=i
end do
b=cshift(a,draw())
s=b(1)-1
do i=1,257
if(b(i)/=modulo(i-1+s,257)+1) error stop 1
end do
print *, "PASS"
contains
integer function draw() result(r)
real(8)::x
call random_number(x)
r=int(x*257d0)
end function
end program
