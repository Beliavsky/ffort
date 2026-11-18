program elemental_test
implicit none

print *,compute(2)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in),optional::xx
rr=xx*xx+1
end function compute

end program
