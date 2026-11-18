program p
implicit none
character(3),allocatable :: x(:)
integer :: n
n=0
call fill(n,x)
print *,999
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=6/n),allocatable,intent(out) :: a(:)
allocate(a(1))
end subroutine
end program
