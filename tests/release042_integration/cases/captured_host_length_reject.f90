module captured
implicit none
integer::n
contains
subroutine fill(a)
character(len=n),allocatable,intent(out)::a(:)
n=1
allocate(a(1))
a='Z'
end subroutine
end module
program p
use captured
implicit none
character(3),allocatable::x(:)
n=3
call fill(x)
if(n/=1.or.len(x)/=3) error stop 1
print '(a)',x(1)
end program
