module gmod
implicit none
interface choose
module procedure f
end interface
contains
integer function f(a,b,c) result(r)
integer,optional,intent(in)::a,b
integer,optional,intent(in)::c
r=0
if(present(c))r=c
if(present(a))r=r+10*a
if(present(b))r=r+100*b
end function
end module
program p
use gmod
implicit none
print '(i0)',choose()
end program
