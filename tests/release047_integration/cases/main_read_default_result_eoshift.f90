module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
contains
function make(n) result(r)
integer,intent(in)::n
type(dt)::r
r%a=r%a+n
end function
end module
program p
use types
implicit none
type(dt)::x
integer::a(3),u,n,k
u=27
read(u,*)n
x=make(n)
k=x%a
a=eoshift([1,2,3],1,boundary=k)
print '(3i3,f5.1)',a,x%y
end program
