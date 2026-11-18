program p
implicit none

print *,f(3)
contains
function f(n) result(y)
integer,intent(in)::n
integer::y(n)
y=n
return
y=0
end function
end program
