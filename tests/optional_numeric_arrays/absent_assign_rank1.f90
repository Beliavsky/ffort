program main
implicit none
call f()
contains
subroutine f(x)
integer,optional,intent(inout)::x(:)
x=2
end subroutine
end program
