program main
if(any(ubound(f())/=[3,2])) error stop 1
contains
function f() result(x)
real::x(-2:0,5:6)
x=1
end function
end program
