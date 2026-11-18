program elemental_test
implicit none

print *,compute(yy=2)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
