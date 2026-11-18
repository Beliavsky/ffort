module record_types
implicit none
type :: pair
 integer :: left,right
end type
end module
program p
use record_types
implicit none
type(pair) :: a,b
character(4),allocatable :: x(:)
character(2),allocatable :: y(:)
integer :: n
a=pair(7,9)
b=a
n=4
call outer(a,n,x)
if(n/=1.or.len(x)/=4.or.lbound(x,1)/=-1) error stop 1
if(a%left/=8.or.a%right/=9.or.b%left/=7.or.b%right/=9) error stop 2
n=2
call outer(a,n,y)
if(n/=1.or.len(y)/=2.or.a%left/=9.or.b%left/=7) error stop 3
print '(a)',x(-1)
print '(a)',y(0)
contains
subroutine outer(r,n,v)
type(pair),intent(inout)::r
integer,intent(inout)::n
character(len=n),allocatable,intent(out)::v(:)
call inner(r,n,v)
end subroutine
subroutine inner(r,n,v)
type(pair),intent(inout)::r
integer,intent(inout)::n
character(len=n),allocatable,intent(out)::v(:)
n=1
r%left=r%left+1
allocate(v(-1:0))
v='Q'
end subroutine
end program
