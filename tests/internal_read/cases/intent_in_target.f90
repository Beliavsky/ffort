module m
implicit none
contains
subroutine f(text,n)
character(*),intent(in)::text
integer,intent(in)::n
read(text,*) n
end subroutine
end module
program p
use m
implicit none
call f('1',1)
end
