program p
implicit none
character(65536),allocatable :: x(:)
call fill(65536,x)
if (len(x)/=65536 .or. size(x)/=0) error stop 1
print *,1
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
allocate(a(0))
end subroutine
end program
