module arithmetic_module
implicit none
contains
simple integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx+2
end function helper

end module
program purity_test
use arithmetic_module, only : helper
implicit none
print *,compute(5)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=helper(xx)*3
end function compute

end program
