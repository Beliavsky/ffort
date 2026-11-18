program purity_test
implicit none

print *,991
contains
simple subroutine adjust(xx)
integer, intent(inout) :: xx
print *,xx
end subroutine adjust

end program
