program elemental_test
implicit none

print *,compute(3)
contains
elemental function compute(xx) result(rr)
integer,intent(in)::xx
integer::rr
rr=xx*xx+1
end function compute

end program
