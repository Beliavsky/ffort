program p
print *,f(7)
contains
integer function f(x) result(max)
integer,intent(in)::x
max=x+1
end function
end program
