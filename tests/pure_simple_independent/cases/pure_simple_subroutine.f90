program purity_test
implicit none
integer::aa
aa=4
call adjust(aa)
print *,aa
contains
pure simple subroutine adjust(xx)
integer, intent(inout) :: xx
xx=xx+7
end subroutine adjust

end program
