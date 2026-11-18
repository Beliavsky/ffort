program purity_test
implicit none

print *,compute(xx=4)
contains
integer simple function compute(xx) result(rr)
integer, intent(in) :: xx
rr=xx*xx+1
end function compute

end program
