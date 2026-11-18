module m
implicit none
contains
subroutine show(s,n)
character(*),intent(in)::s
integer,intent(in)::n
character(len(s))::a(2)
a=[s,s]
print '(*(a))','[',a,']'
print '(o4.4)',ior(n,8)
end subroutine
end module
program p
use m
implicit none
call show('A',1)
call show('Bc ',2)
end program
