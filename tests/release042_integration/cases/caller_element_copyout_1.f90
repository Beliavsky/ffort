program p
implicit none
integer,allocatable :: owned(:)
character(0),allocatable :: x(:)
allocate(owned(999999))
call fill(0,x)
if(size(x)/=1.or.lbound(x,1)/=-2) error stop 1
print '(a)','ok'
contains
subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
allocate(a(-2:-2))
end subroutine
end program
