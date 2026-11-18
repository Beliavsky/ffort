program p
implicit none

print *,f(2)
contains
elemental function f(n) result(y)
integer,intent(in)::n
integer::y(2)
y=n
end function
end program
