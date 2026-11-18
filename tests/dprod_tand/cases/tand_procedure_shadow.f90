program p
implicit none

print *,tand(3)
contains
integer function tand(x)
integer,intent(in)::x
tand=x+1
end function
end program
