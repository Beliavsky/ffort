program p
implicit none
character(5),allocatable :: x(:)
call inspect(5,x,0)
allocate(x(0))
call inspect(5,x,1)
deallocate(x)
allocate(x(-1:0))
x='hello'
call inspect(5,x,2)
print *,1
contains
subroutine inspect(n,a,phase)
integer,intent(in) :: n,phase
character(len=n),allocatable,intent(in) :: a(:)
if (len(a)/=5) error stop 1
if (phase==0) then
 if (allocated(a)) error stop 2
else
 if (.not.allocated(a)) error stop 3
 if (phase==1 .and. size(a)/=0) error stop 4
 if (phase==2) then
  if (lbound(a,1)/=-1 .or. size(a)/=2) error stop 5
  if (any(a/='hello')) error stop 6
 end if
end if
end subroutine
end program
