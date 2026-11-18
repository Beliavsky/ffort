module m
implicit none
contains
subroutine f(text)
character(*),intent(in)::text
integer,save::n
read(text,*) n
end subroutine
end module
program p
use m
implicit none
call f('1')
end
