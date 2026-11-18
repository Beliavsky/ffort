program p
implicit none
integer(8)::x
if(digits(x)/=63)error stop 1
print *,digits(x),kind(digits(x))
end program
