program elemental_test
implicit none
integer::aa(2)
aa=3
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx
call bump(rr)
end function compute
pure subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+2
end subroutine
end program
