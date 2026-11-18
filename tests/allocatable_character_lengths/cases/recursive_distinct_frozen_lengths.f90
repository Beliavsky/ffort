program p
implicit none
character(4),allocatable :: x(:)
character(2),allocatable :: y(:)
call fill(4,x)
if (len(x)/=4 .or. size(x)/=1 .or. x(1)/='xxxx') error stop 1
call fill(2,y)
if (len(y)/=2 .or. y(1)/='xx') error stop 2
print *,1
contains
recursive subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
character(len=n-1),allocatable :: child(:)
allocate(a(1))
a=''
if (n>0) then
 call fill(n-1,child)
 if (len(child)/=n-1) error stop 3
 if (len(a)/=n) error stop 4
 a(1)=child(1)//'x'
end if
end subroutine
end program
