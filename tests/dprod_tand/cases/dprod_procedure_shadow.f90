program p
implicit none

print *,dprod(3)
contains
integer function dprod(x)
integer,intent(in)::x
dprod=x+1
end function
end program
