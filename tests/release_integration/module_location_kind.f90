module m
integer::a(2,2),d=3
contains
integer function query()
query=kind(minloc(a,dim=d,kind=8))
end function
end module
program p
use m
print *,query(),kind(maxloc(a,kind=8))
end
