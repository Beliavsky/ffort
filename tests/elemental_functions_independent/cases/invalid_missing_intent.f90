program elemental_test
implicit none

print *,991
contains
elemental integer function compute(xx) result(rr)
integer::xx
rr=xx
end function compute

end program
