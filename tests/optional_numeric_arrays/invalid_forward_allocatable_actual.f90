program main
implicit none
call outer()
contains
subroutine outer(a)
integer,optional,intent(in)::a(:)
call inner(a)
end subroutine
subroutine inner(x)
integer,allocatable,optional,intent(in)::x(:)
end subroutine
end program
