program p
implicit none
character(4),allocatable :: x(:)
integer :: n
allocate(x(3))
x=['abcd','efgh','ijkl']
n=4
call alter(n,x)
if (n/=2 .or. len(x)/=4 .or. size(x)/=1) error stop 1
if (x(1)/='wxyz') error stop 2
print *,1
contains
subroutine alter(n,a)
integer,intent(inout) :: n
character(len=n),allocatable,intent(inout) :: a(:)
n=2
if (len(a)/=4) error stop 3
a=a(2:)
if (len(a)/=4 .or. size(a)/=2) error stop 4
if (any(a/=['efgh','ijkl'])) error stop 5
deallocate(a)
if (len(a)/=4) error stop 6
allocate(a(1))
a='wxyz12'
if (len(a)/=4 .or. a(1)/='wxyz') error stop 7
end subroutine
end program
