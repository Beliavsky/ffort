program main
implicit none
call outer()
contains
subroutine outer(x)
character(*),optional,intent(in)::x
call required(x)
end subroutine
subroutine required(x)
character(*),intent(in)::x
end subroutine
end program
