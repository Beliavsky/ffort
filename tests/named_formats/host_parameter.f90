program p
implicit none
character(*),parameter::fmt='(i0)'
call show()
contains
subroutine show()
print fmt,12
end subroutine
end program
