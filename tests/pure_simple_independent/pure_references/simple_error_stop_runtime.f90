program purity_test
implicit none

print *,112
print *,compute(-1)
contains
pure integer function compute(xx) result(rr)
integer, intent(in) :: xx
if(xx<0) error stop 77
rr=xx
end function compute

end program
