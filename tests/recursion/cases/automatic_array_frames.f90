program p
implicit none

print *,sumtail([2,4,6,8])
contains
pure recursive integer function sumtail(a) result(v)
integer,intent(in)::a(:)
integer::local(size(a)),saved
local=a
saved=size(a)
if(saved==0) then
v=0
else
v=local(1)+sumtail(local(2:saved))
v=v+sum(local)-sum(a)
end if
end function
end program
