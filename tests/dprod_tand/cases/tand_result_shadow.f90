program p
implicit none

print *,f(3)
contains
integer function f(x) result(tand)
integer,intent(in)::x
tand=x+2
end function
end program
