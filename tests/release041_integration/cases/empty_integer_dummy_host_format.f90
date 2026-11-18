module m
implicit none
character(len=*),parameter::fmt='(2(i0,1x))'
contains
subroutine show(a)
integer(kind=8),intent(in)::a(:)
print fmt,size(a),kind(a)
end subroutine
end module
program p
use m
implicit none
call show([integer(kind=8)::])
end program
