program main
implicit none
real(8)::x(2),a(2,2,2),b(2,2,2)
x=[3.0_8,4.0_8]
a=2.0_8
b=abs(-norm2(x))+a
if(any(b(:,:,1)/=7.0_8).or.any(b(:,:,2)/=7.0_8)) error stop 1
end program
