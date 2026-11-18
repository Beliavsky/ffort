module record_types
implicit none
type::pair
integer::left,right
end type
end module
program p
use record_types
implicit none
type(pair)::a,b
character(2),allocatable::x(:)
a=pair(7,9)
b=a
call fill(2,a,x)
if(b%left/=7.or.b%right/=9) error stop 1
print *,a%right
contains
subroutine fill(n,r,v)
integer,intent(in)::n
type(pair),intent(out)::r
character(len=n),allocatable,intent(out)::v(:)
r%left=8
allocate(v(1))
v='ok'
end subroutine
end program
