module m
implicit none
integer :: calls=0
contains
integer function idx()
calls=calls+1
idx=1
end function
end module
use m
implicit none
character(4)::x(1)=['abcd']
x(idx())(2:3)='PQ'
print '(a)',x(idx())(2:3)
print '(i0)',calls
end
