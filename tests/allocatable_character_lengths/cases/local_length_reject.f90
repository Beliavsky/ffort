program p
implicit none
character(3),allocatable :: x(:)
call fill(x)
contains
subroutine fill(a)
integer :: n
character(len=n),allocatable,intent(out) :: a(:)
n=3
allocate(a(1))
end subroutine
end program
