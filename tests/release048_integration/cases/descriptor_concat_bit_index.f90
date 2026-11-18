module m
implicit none
contains
subroutine show(s)
character(*),intent(in)::s(:)
character(4)::a(2)
integer::i
a=[(s(1)//s(2),i=1,2)]
print '(*(a))',a
print '(2b4.4)',[(ior(i,8),i=1,2)]
end subroutine
end module
program p
use m
implicit none
call show(['ab','CD'])
end program
