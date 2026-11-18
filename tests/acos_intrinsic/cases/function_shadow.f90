program p
implicit none

print *,acos(3)
contains
integer function acos(x)
integer,intent(in)::x
acos=x+1
end function
end program
