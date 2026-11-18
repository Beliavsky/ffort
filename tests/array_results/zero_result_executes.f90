program p
implicit none

print *,sum(f(0))
contains
function f(n) result(y)
integer,intent(in)::n
integer::y(n)
error stop 'empty body executed'
end function
end program
