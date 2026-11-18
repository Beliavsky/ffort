program main
implicit none
call outer()
contains
subroutine outer(a)
integer(4),optional,intent(in)::a(:)
call inner(a)
end subroutine
subroutine inner(x)
integer(8),optional,intent(in)::x(:)
end subroutine
end program
