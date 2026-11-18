program p
implicit none
integer(4)::x(2,1,2)
if(digits(x)/=31)error stop 1
print *,digits(x)
end program
