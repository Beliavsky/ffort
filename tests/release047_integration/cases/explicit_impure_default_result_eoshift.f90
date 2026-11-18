module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
contains
impure function make(u) result(r)
integer,intent(in)::u
type(dt)::r
integer::n
read(u,*)n
r%a=r%a+n
end function
end module
program p
use types
implicit none
type(dt)::x
integer::a(3),k
x=make(27)
k=x%a
a=eoshift([1,2,3],1,boundary=k)
print '(3i3,f5.1)',a,x%y
end program
