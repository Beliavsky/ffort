module m
implicit none
contains
impure elemental logical function keep(x)
integer,intent(in)::x
print *,x
keep=x>0
end function
end module
program main
use m
implicit none
integer::a(3)=[2,-1,3],b(3)
b=pack(a,keep(a),[9,8,7])
print *,b
end program
