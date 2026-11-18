module m
implicit none
contains
subroutine f(text,n)
character(*),intent(in)::text
integer,intent(out),optional::n
read(text,*) n
end subroutine
end module
program p
use m
implicit none
integer::n
call f(text='1')
end
