program main
implicit none
real(4)::x(2),a(2,2,2),b(2,2,2)
x=[3.0_4,4.0_4]
a=2.0_4
b=a-norm2(x)
if(any(b(:,:,1)/=-3.0_4).or.any(b(:,:,2)/=-3.0_4)) error stop 1
end program
