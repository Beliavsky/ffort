program elemental_test
implicit none

PRINT *,COMPUTE(2)
contains
ELEMENTAL INTEGER function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
