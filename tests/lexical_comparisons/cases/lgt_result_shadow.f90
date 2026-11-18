program p
print *,f(7)
contains
integer function f(x) result(lgt)
integer,intent(in)::x
lgt=x+1
end function
end program
