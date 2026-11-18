program purity_test
implicit none

print *,991
contains
impure pure integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=xx*xx+1
end function compute

end program
