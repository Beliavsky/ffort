program p
implicit none
if(transpose(3)/=4) error stop 1
contains
integer function transpose(x)
integer,intent(in)::x
transpose=x+1
end function
end program
