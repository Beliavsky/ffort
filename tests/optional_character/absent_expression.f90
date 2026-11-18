program main
implicit none
call outer()
contains
subroutine outer(x)
character(*),optional,intent(in)::x
call inner(x//'z')
end subroutine
subroutine inner(x)
character(*),optional,intent(in)::x
end subroutine
end program
