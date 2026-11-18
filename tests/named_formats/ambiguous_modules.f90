module m
implicit none
character(*),parameter::fmt='(i0)'
end module
module n
implicit none
character(*),parameter::fmt='(i0)'
end module
program p
use m
use n
implicit none
print fmt,1
end program
