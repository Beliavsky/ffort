module m
character(8)::fmt='(i0)'
end module
program p
use m
implicit none
print fmt,8
end program
