module record_mod
implicit none
type::record
 integer::n=2
end type
end module
program main
use record_mod
implicit none
integer::x(3,1)
type(record)::r
x(:,1)=[1,2,3]
print '(i0)',x([r%n,1,r%n],:)
end program
