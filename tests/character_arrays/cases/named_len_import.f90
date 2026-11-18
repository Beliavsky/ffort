module m
integer,parameter::n=3
end module
program p
use m
implicit none
character(n)::a(2)=[character(n)::"x","yz"]
print *,a
end
