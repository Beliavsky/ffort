program p
print *,f(7)
contains
function f(x) result(iand)
integer,intent(in)::x
integer::iand
iand=x+1
end function
end program
