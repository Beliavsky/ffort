program p
implicit none
real(8)::x(4)
real(4)::a(4),b(4)
x=[0.499999999999d0,-0.499999999999d0,1.999999999999d0,-1.999999999999d0]
print *,aint(x,4),anint(x,4)
print *,aint(1.999999999999d0,4),anint(0.499999999999d0,4)
a=aint(x)
b=anint(x)
print *,a,b
end program
