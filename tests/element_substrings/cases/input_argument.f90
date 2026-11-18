module m
contains
subroutine show(x)
character(*),intent(in)::x
print '(a)',x
end subroutine
end module
use m
implicit none
character(4)::x(2)=['abcd','efgh']
call show(x(2)(2:3))
call show((x(1)(2:)))
end
