program purity_test
implicit none

print *,compute(3)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
if(xx<0) error stop 77
rr=xx+1
end function compute

end program
