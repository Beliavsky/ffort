program p
implicit none

call show('(i0)')
contains
subroutine show(fmt)
character(*),intent(in),optional::fmt
print fmt,8
end subroutine
end program
