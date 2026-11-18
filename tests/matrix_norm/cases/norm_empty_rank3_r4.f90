program p
implicit none
real(4)::x(2,0,3),a(2,3)
a=norm2(x,2)
if(any(a/=0.0).or.norm2(x)/=0.0) error stop 1
if(any(shape(norm2(x,1))/=[0,3]).or.any(shape(norm2(x,3))/=[2,0])) error stop 2
end program
