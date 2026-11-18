program p
implicit none

print *,f(3)
contains
integer function f(x) result(acos)
integer,intent(in)::x
acos=x+2
end function
end program
