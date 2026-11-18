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
type(record)::r
x=r%s
x(2)='DEF'
print '(a)',x([r%n,1,r%n])
end program
