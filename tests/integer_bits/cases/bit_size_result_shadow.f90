program p
print *,f(7)
contains
function f(x) result(bit_size)
integer,intent(in)::x
integer::bit_size
bit_size=x+1
end function
end program
