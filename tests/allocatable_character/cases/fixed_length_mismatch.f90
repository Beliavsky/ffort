program main
implicit none
character(4),allocatable::a(:)
call bad(a)
contains
subroutine bad(x)
character(3),allocatable,intent(out)::x(:)
allocate(x(1))
end subroutine

end program
