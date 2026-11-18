program p
implicit none

print '(a)',chars(5)
print '(a)',chars(2)
contains
recursive function chars(n) result(v)
integer,intent(in)::n
character(n)::v,local
local='x'
if(n==0) then
v=''
else
v=chars(n-1)//local(1:1)
end if
end function
end program
