program purity_test
implicit none
integer :: aa
aa=8
call adjust(xx=aa)
print *,aa
contains
pure subroutine adjust(xx)
integer, intent(inout) :: xx
xx=xx+7
end subroutine adjust

end program
