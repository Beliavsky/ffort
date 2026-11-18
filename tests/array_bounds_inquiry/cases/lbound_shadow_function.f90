program p
implicit none
if(lbound(array=4)/=14)error stop 1
contains
integer function lbound(array)result(v)
integer,intent(in)::array
v=array+10
end function
end program
