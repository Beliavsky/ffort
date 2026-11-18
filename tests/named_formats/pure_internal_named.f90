module m
implicit none
contains
pure function convert(i) result(s)
integer,intent(in)::i
character(4)::s
character(*),parameter::fmt='(i0)'
write(s,fmt)i
end function
end module
program p
use m,only:convert
implicit none
print '(a)',convert(12)
end program
