program p
implicit none
print *,rrspacing(2)
contains
integer function rrspacing(x)
integer,intent(in)::x
rrspacing=x+1
end function
end program
