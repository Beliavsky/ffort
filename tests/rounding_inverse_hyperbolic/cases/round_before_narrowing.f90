program p
implicit none
real(8)::x(4)
x=[0.499999999999d0,-0.499999999999d0,1.999999999999d0,-1.999999999999d0]
print *,aint(x,4),anint(x,4)
end program
