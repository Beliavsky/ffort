module m
character(8)::fmt='(i0)'
contains
subroutine show()
print fmt,8
end subroutine
end module
program p
use m
call show()
end program
