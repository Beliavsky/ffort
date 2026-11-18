program p
implicit none
real(4)::x(0,3),a(3),b(0)
a=norm2(x,1)
b=norm2(x,2)
if(any(a/=0.0).or.size(b)/=0.or.norm2(x)/=0.0) error stop 1
end program
