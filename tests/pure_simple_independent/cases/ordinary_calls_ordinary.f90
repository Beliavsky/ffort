program purity_test
implicit none
integer :: aa
aa=4
call driver(aa)
print *,aa
contains
 subroutine driver(xx)
integer, intent(inout) :: xx
xx=compute(xx)
call adjust(xx)
end subroutine driver
integer function compute(xx) result(rr)
integer, intent(in) :: xx
rr=xx*xx+1
end function compute
 subroutine adjust(xx)
integer, intent(inout) :: xx
xx=xx+7
end subroutine adjust

end program
