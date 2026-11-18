program p
implicit none

print *,f(3)
contains
integer function f(x) result(dprod)
integer,intent(in)::x
dprod=x+2
end function
end program
