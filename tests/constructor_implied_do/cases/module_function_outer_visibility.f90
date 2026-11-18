module m
implicit none
integer::i=88
contains
integer function see_outer() result(r)
r=i
end function
end module
program main
use m
implicit none
integer::a(6)
a=[(i,see_outer(),i=1,3)]
print *,a,i
end program
