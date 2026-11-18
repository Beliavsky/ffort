module spec
implicit none
contains
subroutine calculate(a)
real(8),intent(in)::a(:,:)
integer::work(radix(a)+kind(tiny(a)))
work=1
write(*,'("spec:",3(1x,i0))')size(work),sum(work),kind(epsilon(log_gamma(a)))
end subroutine
end module
program main
use spec
implicit none
real(8)::a(0,3)
integer::idx(0)
call calculate((a(idx,:)))
end program
