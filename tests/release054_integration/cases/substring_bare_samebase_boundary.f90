module m
implicit none
contains
subroutine capture(src,dst)
character(*),intent(in) :: src
character(*),intent(out) :: dst
dst=src//'!'
end subroutine
end module
program p
use m
implicit none
character(4) :: a(2)
a(1)='ABCD'
a(2)='WXYZ'
write(*,'(a)',advance='no') 'KEEP'
call capture(a(1)(2:3),a(2))
write(*,'(a)') 'unexpected entry'
end program
