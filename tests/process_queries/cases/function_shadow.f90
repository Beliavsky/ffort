program p
implicit none
if(getcwd(3)/=4) error stop 1
contains
integer function getcwd(n) result(v)
integer,intent(in)::n
v=n+1
end function
end program
