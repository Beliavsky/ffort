program purity_test
implicit none

print *,compute(3)
contains
simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=xx
call adjust(rr)
end function compute
simple subroutine adjust(xx)
integer, intent(inout) :: xx
xx=xx+7
end subroutine adjust

end program
