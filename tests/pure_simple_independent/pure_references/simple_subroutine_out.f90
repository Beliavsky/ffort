program purity_test
implicit none
integer :: aa
call adjust(aa)
print *,aa
contains
pure subroutine adjust(xx)
integer, intent(out) :: xx
xx=23
end subroutine adjust

end program
