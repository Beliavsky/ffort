program purity_test
implicit none
integer :: aa
print *,compute(5)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=helper(xx)
end function compute
integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx+7
end function helper

end program
