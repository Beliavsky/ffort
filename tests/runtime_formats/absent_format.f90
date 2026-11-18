program p
implicit none

call show()
contains
subroutine show(fmt)
character(*),intent(in),optional::fmt
print fmt,1
end subroutine
end program
