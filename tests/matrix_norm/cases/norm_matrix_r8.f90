program p
implicit none
real(8)::x(2,3),a(3),b(2)
x=reshape([1.0_8,2.0_8,3.0_8,4.0_8,5.0_8,6.0_8],[2,3])
a=norm2(x,dim=1)
b=norm2(x,dim=2)
if(any(abs(a-sqrt([5.0_8,25.0_8,61.0_8]))>2d-14)) error stop 1
if(any(abs(b-sqrt([35.0_8,56.0_8]))>2d-14)) error stop 2
if(abs(norm2(x)-sqrt(91.0_8))>2d-14) error stop 3
end program
