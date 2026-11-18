program purity_test
implicit none

print *,compute(3)
contains
SIMPLE integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=xx*2
end function compute

end program
