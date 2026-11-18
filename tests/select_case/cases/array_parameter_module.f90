module m
implicit none
integer,parameter::a(2)=[3,4]
contains
integer function f() result(r)
r=sum(a)
end function
end module
program p
use m
implicit none
print *,a,f()
end program
