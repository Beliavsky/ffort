program p
implicit none
integer::missing
print *,kind(bad(missing))
contains
function bad(n) result(y)
integer,intent(in)::n
real(8)::y(n)
error stop 1
end function
end program
