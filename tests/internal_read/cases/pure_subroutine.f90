module m
implicit none
contains
pure subroutine f(text,n)
character(*),intent(in)::text
integer,intent(out)::n
read(text,*) n
end subroutine
end module
program p
use m
implicit none
integer::n
call f('42',n)
if(n/=42) stop 1
print *,1
end
