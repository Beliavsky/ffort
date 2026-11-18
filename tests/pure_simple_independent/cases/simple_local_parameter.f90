program purity_test
implicit none

print *,compute(5)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
integer, parameter :: scale=3
rr=scale*xx
end function compute

end program
