program p
implicit none
integer::b(0)
b=cshift(make(0),1)
print *, "PASS"
contains
function make(n) result(r)
integer,intent(in)::n
integer::r(n)
error stop "ARRAY descriptor evaluated"
end function
end program
