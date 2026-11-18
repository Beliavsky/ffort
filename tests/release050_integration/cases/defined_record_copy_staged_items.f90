module m
implicit none
type::box
integer::a,n=4,b
character(3)::s='Ab'
end type
end module
program p
use m
implicit none
type(box)::x,y
integer::n
character(8)::buf(2)
x%a=1
x%b=2
y=x
x%s='Q'
n=y%n
write(buf(2),'(a,1x,z2.2)')y%s,maskr(n)
print '(a)','['//buf(2)//']'
end program
