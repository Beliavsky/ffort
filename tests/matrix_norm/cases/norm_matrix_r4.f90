program p
implicit none
real(4)::x(2,3),a(3),b(2)
x=reshape([1.0_4,2.0_4,3.0_4,4.0_4,5.0_4,6.0_4],[2,3])
a=norm2(x,dim=1)
b=norm2(x,dim=2)
if(any(abs(a-sqrt([5.0_4,25.0_4,61.0_4]))>2e-6)) error stop 1
if(any(abs(b-sqrt([35.0_4,56.0_4]))>2e-6)) error stop 2
if(abs(norm2(x)-sqrt(91.0_4))>2e-6) error stop 3
end program
