program elemental_test
implicit none

print *,991
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
call set_value(xx)
rr=xx
end function compute
pure subroutine set_value(xx)
integer,intent(out)::xx
xx=2
end subroutine
end program
