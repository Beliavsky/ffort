program p
print *,f(7)
contains
integer function f(x) result(lle)
integer,intent(in)::x
lle=x+1
end function
end program
