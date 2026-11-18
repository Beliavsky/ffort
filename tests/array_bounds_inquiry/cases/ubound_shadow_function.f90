program p
implicit none
if(ubound(array=4)/=14)error stop 1
contains
integer function ubound(array)result(v)
integer,intent(in)::array
v=array+10
end function
end program
