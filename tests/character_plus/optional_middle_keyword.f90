module gmod
implicit none
interface choose
module procedure f
end interface
contains
integer function f(a,b,c) result(r)
integer,optional,intent(in)::a,b
integer,intent(in)::c
r=c
if(present(a))r=r+10*a
if(present(b))r=r+100*b
end function
end module
program p
use gmod
implicit none
print '(i0)',choose(c=3),choose(2,c=3),choose(c=3,b=2,a=1)
end program
