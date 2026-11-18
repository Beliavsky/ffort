program p
implicit none
character(65536),allocatable :: x(:)
call fill(65536,x)
if (allocated(x)) error stop 1
print *,1
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
integer :: status
allocate(a(257),stat=status)
if (status==0) error stop 2
if (allocated(a)) error stop 3
end subroutine
end program
