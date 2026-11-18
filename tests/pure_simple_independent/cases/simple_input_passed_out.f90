program purity_test
implicit none

print *,991
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
call set_value(xx)
rr=xx
end function compute
simple subroutine set_value(xx)
integer,intent(out)::xx
xx=9
end subroutine set_value

end program
