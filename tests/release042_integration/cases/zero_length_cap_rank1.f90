program p
implicit none
character(0),allocatable :: x(:)
call fill(0,x)
if (len(x)/=0.or.size(x)/=2) error stop 1
print '(a)','ok'
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
integer :: s
allocate(a(-2:999997),stat=s)
if(s/=0.or.size(a)/=1000000.or.len(a)/=0) error stop 2
if(lbound(a,1)/=-2) error stop 3
deallocate(a)
allocate(a(1000001),stat=s)
if(s==0.or.allocated(a).or.len(a)/=0) error stop 4
allocate(a(-1:0),stat=s)
if(s/=0) error stop 5
end subroutine
end program
