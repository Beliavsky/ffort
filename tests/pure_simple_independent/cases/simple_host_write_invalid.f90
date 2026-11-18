program purity_test
implicit none
integer :: scale
print *,991
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
scale=xx
rr=xx
end function compute

end program
