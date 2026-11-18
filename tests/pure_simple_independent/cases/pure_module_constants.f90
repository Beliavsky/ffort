module arithmetic_module
implicit none
integer, parameter :: weight=3
contains
pure integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=helper(xx)+weight
end function compute

pure integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx*2
end function helper

end module
program purity_test
use arithmetic_module, only : compute
implicit none
print *,compute(4)
end program
