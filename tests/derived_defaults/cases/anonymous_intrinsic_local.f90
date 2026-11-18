module constants
implicit none
integer,parameter::n=12
end module
use constants
implicit none
integer::x
x=n+3
print '(i0)',x
end
