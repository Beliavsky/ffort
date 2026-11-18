program p
if(f(2)/=3) error stop 1
print *, 'result name'
contains
integer function f(x) result(procedure)
integer,intent(in)::x
procedure=x+1
end function
end program
