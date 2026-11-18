program p
implicit none
character(4),allocatable :: x(:)
call touch(4,x,x)
print *,999
contains
subroutine touch(n,a,b)
integer,intent(in) :: n
character(len=n),allocatable,intent(inout) :: a(:)
character(len=n),allocatable,intent(in) :: b(:)
if (allocated(a)) deallocate(a)
allocate(a(1))
a='abcd'
if (allocated(b)) print *,997
end subroutine
end program
