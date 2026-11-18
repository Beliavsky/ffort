program p
implicit none
print *,f(3)
contains
integer function f(x) result(repeat)
integer,intent(in)::x
repeat=x+20
end function
end program
