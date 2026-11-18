program p
implicit none
character(4),allocatable :: x(:)
call outer(4,x,.true.)
if (.not.allocated(x)) error stop 1
if (len(x)/=4 .or. size(x)/=2 .or. lbound(x,1)/=-1) error stop 2
if (any(x/='abcd')) error stop 3
call outer(4,x,.false.)
if (allocated(x)) error stop 4
if (len(x)/=4) error stop 5
print *,1
contains
subroutine outer(n,a,fill)
integer,intent(in) :: n
logical,intent(in) :: fill
character(len=n),allocatable,intent(out) :: a(:)
if (allocated(a)) error stop 6
call inner(n,a,fill)
end subroutine
subroutine inner(n,a,fill)
integer,intent(in) :: n
logical,intent(in) :: fill
character(len=n),allocatable,intent(out) :: a(:)
if (allocated(a)) error stop 7
if (fill) then
 allocate(a(-1:0))
 a='abcdef'
end if
end subroutine
end program
