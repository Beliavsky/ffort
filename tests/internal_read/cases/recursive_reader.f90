module m
implicit none
contains
recursive integer function f(k,text) result(n)
integer,intent(in)::k
character(*),intent(in)::text
integer::v
read(text,*) v
n=v
if(k>0) n=n+f(k-1,text)
end function
end module
program p
use m
implicit none
if(f(3,'2')/=8) stop 1
print *,1
end
