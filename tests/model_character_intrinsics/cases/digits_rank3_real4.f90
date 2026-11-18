program p
implicit none
real(4)::x(2,1,2)
if(digits(x)/=24)error stop 1
print *,digits(x)
end program
