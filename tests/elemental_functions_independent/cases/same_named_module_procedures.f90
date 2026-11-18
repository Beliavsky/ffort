module scalar_ops
implicit none
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+100
end function
end module
module array_ops
implicit none
contains
elemental logical function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx>2
end function
end module
program elemental_test
use array_ops, only: compute
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,compute(aa)
end program
