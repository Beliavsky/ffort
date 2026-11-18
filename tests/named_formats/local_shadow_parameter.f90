program p
implicit none
character(*),parameter::fmt='("outer",i0)'
print fmt,1
call show()
contains
subroutine show()
character(*),parameter::fmt='("inner",i0)'
print fmt,2
end subroutine
end program
