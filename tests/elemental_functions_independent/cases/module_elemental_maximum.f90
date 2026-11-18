module scalar_ops
implicit none
private
public::scalar_wrap
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+100
end function
pure integer function scalar_wrap(xx) result(rr)
integer,intent(in)::xx
rr=compute(xx)
end function
end module
module array_ops
implicit none
private
public::array_wrap
contains
elemental real(8) function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*0.5d0
end function
pure real(8) function array_wrap(xx) result(rr)
integer,intent(in)::xx(:)
rr=sum(compute(max(xx,0)))
end function
end module
program elemental_test
use scalar_ops, only: scalar_wrap
use array_ops, only: array_wrap
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,scalar_wrap(5),array_wrap(aa)
end program
