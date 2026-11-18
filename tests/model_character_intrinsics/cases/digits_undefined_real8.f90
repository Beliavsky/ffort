program p
implicit none
real(8)::x
if(digits(x)/=53)error stop 1
print *,digits(x),kind(digits(x))
end program
