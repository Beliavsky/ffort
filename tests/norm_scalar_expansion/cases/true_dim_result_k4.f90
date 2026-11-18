program main
implicit none
real(4)::x(2,3),a(3)
x(:,1)=[3.0_4,4.0_4]
x(:,2)=[5.0_4,12.0_4]
x(:,3)=[8.0_4,15.0_4]
a=norm2(x,1)+2.0_4
if(any(a/=[7.0_4,15.0_4,19.0_4])) error stop 1
end program
