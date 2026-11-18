program p
implicit none
character(0),allocatable :: x(:)
call fill(-2,x)
if (.not.allocated(x)) error stop 1
if (len(x)/=0 .or. size(x)/=3) error stop 2
if (any(x/='')) error stop 3
print *,1
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
allocate(a(3))
a='abc'
end subroutine
end program
