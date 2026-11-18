program p
implicit none
character(1),allocatable :: x(:)
integer :: n
n=65537
call fill(n,x)
print *,999
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
allocate(a(0))
end subroutine
end program
