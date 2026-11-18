module m
contains
subroutine replace(text,x)
character(*),intent(in)::text
character(*),intent(out)::x
x=text
end subroutine
end module
use m
implicit none
character(4)::x(2)=['abcd','efgh']
call replace((x(1)(2:3)),x(1))
print '(a)',x
end
