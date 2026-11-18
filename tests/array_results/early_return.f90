program p
implicit none

print *,sum(f(2))
contains
function f(n) result(y)
integer,intent(in)::n
integer::y(n)
return
y=1
end function
end program
