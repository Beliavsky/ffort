program p
implicit none
integer(4)::x
if(digits(x)/=31)error stop 1
print *,digits(x),kind(digits(x))
end program
