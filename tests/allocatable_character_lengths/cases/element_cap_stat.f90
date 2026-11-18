program p
implicit none
character(0),allocatable :: x(:)
call fill(0,x)
if (allocated(x)) error stop 1
print *,1
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
integer :: status
allocate(a(1000001),stat=status)
if (status==0) error stop 2
if (allocated(a)) error stop 3
end subroutine
end program
