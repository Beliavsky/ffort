program p
print *,f(7)
contains
function f(x) result(not)
integer,intent(in)::x
integer::not
not=x+1
end function
end program
