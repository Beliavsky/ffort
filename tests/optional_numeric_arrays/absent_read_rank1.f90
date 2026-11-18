program main
implicit none
call f()
contains
subroutine f(x)
integer,optional,intent(inout)::x(:)
print *, x
end subroutine
end program
