module records
implicit none
private
type,public :: pair
integer :: first,second
end type
private :: operator(+)
interface operator(+)
module procedure plus
end interface
contains
function plus(p,n) result(q)
type(pair),intent(in)::p
integer,intent(in)::n
type(pair)::q
q=pair(p%first+n,p%second+n)
end function
end module
program main
use records
implicit none
type(pair)::p,q
p=pair(2,3)
q=p+4
print*,q%first,q%second
end program
