program p
implicit none
character(0),allocatable :: x(:)
allocate(x(-1:1))
call inspect(0,x)
print *,1
contains
subroutine inspect(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(in) :: a(:)
if (len(a)/=0 .or. len(a(999))/=0) error stop 1
if (size(a)/=3 .or. lbound(a,1)/=-1) error stop 2
end subroutine
end program
