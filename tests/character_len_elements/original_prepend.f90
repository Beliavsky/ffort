module utility_case
implicit none
contains
function prepend_char(xadd,xx) result(yy)
! set yy equal to [xadd,xx]
character (len=*), intent(in)                  :: xadd(:)
character (len=*), intent(in)                  :: xx(:)
character (len=len(xx(1)))                     :: yy(size(xx)+size(xadd))
integer                                        :: n,nadd
n = size(xx)
nadd = size(xadd)
yy(1:n) = xx
if (nadd > 0) yy(:nadd) = xadd
yy(nadd+1:) = xx
end function prepend_char
end module
program main
use utility_case
implicit none
character(4)::x(2),empty(0)
character(2)::a(1)
character(4)::y(3),z(1)
x=['abcd','efgh']
a=['xy']
y=prepend_char(a,x)
if(any(y/=['xy  ','abcd','efgh'])) error stop 1
z=prepend_char(a,empty)
if(z(1)/='xy  ') error stop 2
if(len(prepend_char(a,empty))/=4) error stop 3
print *, 'PASS'
end program
