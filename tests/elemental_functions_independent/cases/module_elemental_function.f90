module transforms
implicit none
integer,parameter::offset=3
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+offset
end function
end module
program elemental_test
use transforms, only: compute
implicit none
integer::aa(2)
aa=4
print *,compute(xx=aa)
end program
