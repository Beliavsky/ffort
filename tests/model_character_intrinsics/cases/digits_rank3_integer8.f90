program p
implicit none
integer(8)::x(2,1,2)
if(digits(x)/=63)error stop 1
print *,digits(x)
end program
