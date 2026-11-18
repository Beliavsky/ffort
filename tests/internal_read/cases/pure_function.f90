module m
implicit none
contains
pure integer function f(text) result(n)
character(*),intent(in)::text
integer::stat
read(text,*,iostat=stat) n
if(stat/=0) n=-1
end function
end module
program p
use m
implicit none
if(f('42')/=42.or.f('bad')/=-1) stop 1
print *,1
end
