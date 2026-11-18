program p
implicit none
character(2),allocatable :: x(:)
call outer(2)
call outer(2,x)
if (.not.allocated(x)) error stop 1
if (len(x)/=2 .or. size(x)/=2) error stop 2
if (any(x/='ab')) error stop 3
print *,1
contains
subroutine outer(n,a)
integer,intent(in) :: n
character(len=n),allocatable,optional,intent(out) :: a(:)
call inner(n,a)
end subroutine
subroutine inner(n,a)
integer,intent(in) :: n
character(len=n),allocatable,optional,intent(out) :: a(:)
if (present(a)) then
 if (allocated(a)) error stop 4
 allocate(a(2))
 a='abc'
end if
end subroutine
end program
