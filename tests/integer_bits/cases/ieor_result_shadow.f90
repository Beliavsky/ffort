program p
print *,f(7)
contains
function f(x) result(ieor)
integer,intent(in)::x
integer::ieor
ieor=x+1
end function
end program
