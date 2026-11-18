program main
implicit none
real(8)::x(2,3),a(3)
x(:,1)=[3.0_8,4.0_8]
x(:,2)=[5.0_8,12.0_8]
x(:,3)=[8.0_8,15.0_8]
a=norm2(x,1)+2.0_8
if(any(a/=[7.0_8,15.0_8,19.0_8])) error stop 1
end program
