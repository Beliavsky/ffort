program p
implicit none
character(4),allocatable :: x(:)
integer :: n
allocate(x(2))
x="keep"
n=3
call fill(n,x)
print *,999
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
allocate(a(1))
a='abc'
end subroutine
end program
