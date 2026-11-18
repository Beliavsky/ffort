program p
implicit none
character(0),allocatable :: x(:)
allocate(x(2))
call inspect(0,x)
print *,999
contains
subroutine inspect(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(in) :: a(:)
if (a(1)=='') print *,998
end subroutine
end program
