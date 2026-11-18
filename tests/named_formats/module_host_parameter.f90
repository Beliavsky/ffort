module m
implicit none
character(*),parameter::fmt='(i0)'
contains
subroutine show()
print fmt,12
end subroutine
end module
program p
use m,only:show
implicit none
call show()
end program
