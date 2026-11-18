module arithmetic_module
implicit none
integer :: scale=5
contains
pure integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=scale*xx
end function compute

end module
program purity_test
use arithmetic_module, only : compute
implicit none
print *,compute(2)
end program
