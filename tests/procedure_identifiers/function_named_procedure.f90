program p
if(procedure(2)/=3) error stop 1
print *, 'function name'
contains
integer function procedure(x) result(y)
integer,intent(in)::x
y=x+1
end function
end program
