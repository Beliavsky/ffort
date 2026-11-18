module m
implicit none
integer::i
contains
subroutine f()
do i=1,3
do
return
end do
end do
end subroutine
end module
program p
use m
implicit none

call f()
i=10
print *,i
end program
