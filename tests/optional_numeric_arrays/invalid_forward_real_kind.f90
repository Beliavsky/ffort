program main
implicit none
call outer()
contains
subroutine outer(a)
real(4),optional,intent(in)::a(:)
call inner(a)
end subroutine
subroutine inner(x)
real(8),optional,intent(in)::x(:)
end subroutine
end program
