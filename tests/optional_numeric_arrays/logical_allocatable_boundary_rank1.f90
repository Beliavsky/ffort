program main
implicit none
logical,allocatable::a(:)
call f(a)
contains
subroutine f(x)
logical,allocatable,optional,intent(out)::x(:)
allocate(x(3))
x=.true.
end subroutine
end program
