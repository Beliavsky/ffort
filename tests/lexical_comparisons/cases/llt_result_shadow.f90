program p
print *,f(7)
contains
integer function f(x) result(llt)
integer,intent(in)::x
llt=x+1
end function
end program
