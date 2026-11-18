module unevaluated
implicit none
integer::calls=0
contains
impure elemental function boom() result(x)
real(8)::x
calls=calls+1
x=0d0
x=log_gamma(x)
end function
subroutine optional_model(x)
real(8),optional,intent(in)::x(:,:)
write(*,'("optional:",4(1x,i0))')kind(epsilon(x)),radix(x),kind(tiny(x)),kind(huge(x))
end subroutine
end module
program main
use unevaluated
implicit none
real(8),allocatable::a(:,:)
integer::indices(2)
write(*,'("unallocated:",4(1x,i0))')kind(epsilon(a(indices,:))),radix(a(indices,:)),kind(tiny(a)),kind(huge(a))
write(*,'("unevaluated:",3(1x,i0))')radix(boom()),kind(epsilon(log_gamma(a))),calls
call optional_model()
write(*,'("status:",1x,i0)')merge(1,0,allocated(a))
end program
