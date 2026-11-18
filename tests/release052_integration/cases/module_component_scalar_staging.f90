module record_mod
implicit none
type::record
 character(3)::s="abc"
 integer::n=2
end type
end module
program main
use record_mod
implicit none
character(3)::x(3)
integer::n
type(record)::r
x=r%s
x(2)='DEF'
n=r%n
print '(a)',x([n,1,n])
end program
