program p
implicit none

print *,f()
contains
function f() result(y)
character(2)::y(2)
y='hi'
end function
end program
