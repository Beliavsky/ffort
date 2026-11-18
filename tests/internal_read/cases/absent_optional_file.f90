module m
implicit none
contains
subroutine f(text,n)
character(*),intent(in),optional::text
integer,intent(out)::n
read(text,*) n
end subroutine
end module
program p
use m
implicit none
integer::n
call f(n=n)
end
