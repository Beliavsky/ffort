program p
implicit none
real(4)::x
if(digits(x)/=24)error stop 1
print *,digits(x),kind(digits(x))
end program
