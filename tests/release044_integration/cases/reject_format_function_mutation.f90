module m
implicit none
character(24)::fmt='(*(i0))'
contains
integer function changed(n)
integer,intent(in)::n
fmt='(*(i3.3))'
changed=n
end function
end module
program p
use m
implicit none
integer::i
write(*,fmt)(changed(i),i=1,2)
end program
