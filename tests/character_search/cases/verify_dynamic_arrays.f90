module m
contains
subroutine search(a,b)
character(*),intent(in)::a(:)
logical,optional,intent(in)::b(:)
print *, verify(a,'a',b), sum(verify(a,'a',b))
end subroutine
end module
program p
use m
implicit none
character(3)::a(2),z(0)
a=['aba','baa']
call search(a)
call search(a,[.true.,.false.])
call search(z)
end program
