module m
implicit none
type::box
integer::a,b=4
character(3)::s="cat"
end type
contains
function make(n) result(answer)
integer,intent(in)::n
type(box)::answer,local
if(local%s/="cat".or.local%b/=4)error stop "fresh"
local%s="owl"
answer%a=n
answer%s=repeat("X",n)
end function
end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x,y
integer::u
x=make(1)
y=make(2)
u=output_unit
write(u,"(a,/,a,/,2i2)")x%s,y%s,x%a,y%a
end program
