program p
print *,f(7)
contains
integer function f(x) result(lge)
integer,intent(in)::x
lge=x+1
end function
end program
