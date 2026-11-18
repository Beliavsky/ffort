module m
implicit none
contains
subroutine show(u)
integer,optional,intent(in)::u
write(u,"(a,/,i0)")repeat("X",2),leadz(1)
end subroutine
end module
program p
use m
implicit none
call show()
end program
