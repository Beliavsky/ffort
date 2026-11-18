program p
implicit none
character(6)::s=' abc '
call edit(s(2:4))
contains
subroutine edit(x)
character(*),intent(inout)::x
x=adjustr(x)
end subroutine
end program
