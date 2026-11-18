program purity_test
implicit none

print *,compute(xx=4)
contains
pure function compute(xx) result(rr)
integer, intent(in) :: xx
integer :: rr
rr=xx*xx+1
end function compute

end program
