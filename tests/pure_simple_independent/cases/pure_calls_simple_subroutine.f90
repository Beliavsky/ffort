program purity_test
implicit none
integer :: aa
aa=5
call adjust(aa)
print *,aa
contains
pure subroutine adjust(xx)
integer, intent(inout) :: xx
call helper(xx)
end subroutine adjust
simple subroutine helper(xx)
integer, intent(inout) :: xx
xx=xx+7
end subroutine helper

end program
