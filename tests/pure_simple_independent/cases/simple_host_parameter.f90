program purity_test
implicit none
integer, parameter :: factor=4
print *,compute(5)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=factor*xx
end function compute

end program
