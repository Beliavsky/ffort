program p
print *,f(7)
contains
function f(x) result(btest)
integer,intent(in)::x
integer::btest
btest=x+1
end function
end program
