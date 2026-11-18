module m
character(8)::fmt='(i0)'
contains
integer function change()
fmt='(i3.3)'
change=7
end function
end module
program p
use m
print fmt,change()
print fmt,8
end program
