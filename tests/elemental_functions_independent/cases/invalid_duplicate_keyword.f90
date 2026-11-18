program elemental_test
implicit none

print *,compute(xx=2,xx=3)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
