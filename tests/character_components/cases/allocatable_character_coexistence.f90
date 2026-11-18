module m
implicit none
type::dt
character(3)::s="cat"
end type
end module
program main
use m
implicit none
type(dt)::x
character(:),allocatable::a(:)
allocate(character(2)::a(2))
a=["ab","cd"]
print '(a)',x%s,a
end
