program p
implicit none
character(*),parameter::fmt='(i0)'
call show()
contains
subroutine show()
character(4)::fmt='(i0)'
print fmt,1
end subroutine
end program
