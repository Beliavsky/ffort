program purity_test
implicit none
integer :: scale
scale=6
print *,compute(2)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=scale*xx
end function compute

end program
