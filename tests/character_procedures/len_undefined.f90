module m
implicit none
contains
subroutine unused()
end subroutine
end module m
program test
use m
implicit none
character(5)::a(2)
character(2)::b
integer::i
print *,len(a),len(a(999)),len(a(i:i)),len(b),len(a//b),kind(len(a))
end program test
