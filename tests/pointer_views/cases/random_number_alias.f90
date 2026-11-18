program main
implicit none
real(8),target::a(4)
real(8),pointer::p(:)
a=-1.0_8
p=>a
call random_number(p)
if(any(a<0.0_8).or.any(a>=1.0_8)) error stop 1
print *,1
end program
