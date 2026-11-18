program elemental_test
implicit none

print *,compute(6)
contains
integer elemental function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
