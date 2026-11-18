program p
implicit none
character(4),allocatable :: x(:)
call fill(4,x)
if (len(x)/=4 .or. size(x)/=1 .or. x(1)/='abcd') error stop 1
print *,1
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(inout) :: a(:)
if (allocated(a)) error stop 2
if (len(a)/=4) error stop 3
allocate(a(1))
a='abcdef'
end subroutine
end program
