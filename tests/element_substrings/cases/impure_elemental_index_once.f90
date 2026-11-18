module m
implicit none
integer :: calls=0
contains
impure elemental integer function idx(dummy)
integer,intent(in)::dummy
calls=calls+1
idx=1
end function
end module
use m
implicit none
character(4)::x(1)=['abcd']
x(idx(1))(2:3)='PQ'
print '(a)',x(idx(1))(2:3)
print '(i0)',calls
end
