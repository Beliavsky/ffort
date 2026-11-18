program p
implicit none
real(8)::x(2,3)
x=reshape([-2.5d0,-1d0,0d0,1d0,2.5d0,3d0],[2,3])
print *,aint(x(:,3:1:-1),4),anint(x,8),asinh(x),acosh(abs(x)+1d0)
end program
