program p
implicit none
real(8)::x(2,2,2)
x=-2.5d0
x(:,:,2)=1.75d0
print *,aint(x),anint(x),asinh(x),acosh(abs(x)+1d0)
end program
