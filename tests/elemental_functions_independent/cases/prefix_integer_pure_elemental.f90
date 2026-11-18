program elemental_test
implicit none

print *,compute(4)
contains
integer pure elemental function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
