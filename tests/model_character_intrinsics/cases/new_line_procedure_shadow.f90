program p
implicit none
print *,new_line(2)
contains
integer function new_line(x)
integer,intent(in)::x
new_line=x+1
end function
end program
