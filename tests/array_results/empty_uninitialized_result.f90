program p
implicit none
print *,size(f(0)),size(f(-3))
contains
function f(n) result(y)
integer,intent(in)::n
integer::y(n)
end function
end program
