program elemental_test
implicit none

print *,compute(3)
contains
simple pure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
