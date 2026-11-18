module m
implicit none
contains
impure elemental integer function tick(x) result(v)
integer,intent(in)::x
integer,save::n=0
n=n+1
v=x+n
end function
end module
program p
use m
implicit none
integer::a(3)
a=tick([10,10,10])
print *,a
print *,tick(10)
end program
