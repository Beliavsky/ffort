program p
implicit none
if(norm2(3)/=4) error stop 1
contains
integer function norm2(x)
integer,intent(in)::x
norm2=x+1
end function
end program
