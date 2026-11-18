module m
implicit none
private
character(*),parameter::fmt='(i0)'
end module
program p
use m
implicit none
print fmt,1
end program
