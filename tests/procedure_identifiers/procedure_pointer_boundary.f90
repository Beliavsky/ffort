program p
implicit none
procedure(f),pointer::procedure
contains
integer function f(x) result(y)
integer,intent(in)::x
y=x
end function 
end program
