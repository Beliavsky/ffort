program p
implicit none
character(3),allocatable :: x(:)
call fill(x,3)
contains
subroutine fill(a,n)
integer,optional,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
allocate(a(1))
end subroutine
end program
