program p
implicit none
character(:),allocatable :: x(:)
call fill(3,x)
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
allocate(a(1))
end subroutine
end program
