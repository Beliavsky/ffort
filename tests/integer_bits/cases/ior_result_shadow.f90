program p
print *,f(7)
contains
function f(x) result(ior)
integer,intent(in)::x
integer::ior
ior=x+1
end function
end program
