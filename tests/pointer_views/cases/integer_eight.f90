program main
implicit none
integer(8),target::a(2)
integer(8),pointer::p(:)
a=[2147483648_8,5_8]
p=>a
p(2)=p(1)+1_8
if(a(2)/=2147483649_8) error stop 1
print *,1
end program
