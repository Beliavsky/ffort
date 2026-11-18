program p
implicit none
print *,isnan(f())
contains
function f() result(x)
real(8)::x(2)
x=[1d0,2d0]
end function
end program
