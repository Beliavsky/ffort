program purity_test
implicit none

print *,compute(1)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
if(xx<0) rr=xx
end function compute

end program
