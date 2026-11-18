program purity_test
implicit none
integer :: aa(4)
print *,compute(2)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=size(aa)+xx
end function compute

end program
