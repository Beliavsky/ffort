program elemental_test
implicit none

print *,compute(4)
contains
elemental integer pure function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
