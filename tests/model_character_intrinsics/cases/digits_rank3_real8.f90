program p
implicit none
real(8)::x(2,1,2)
if(digits(x)/=53)error stop 1
print *,digits(x)
end program
