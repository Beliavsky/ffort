program p
print *,f(7)
contains
integer function f(x) result(min)
integer,intent(in)::x
min=x+1
end function
end program
