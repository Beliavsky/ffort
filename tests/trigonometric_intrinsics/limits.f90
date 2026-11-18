program limits
implicit none
real :: x(6)
real(8) :: y(6)
x=[0.0,-0.0,1.0e-20,-1.0e-20,1.0e30,-1.0e30]
y=[0.0d0,-0.0d0,1.0d-200,-1.0d-200,1.0d300,-1.0d300]
print *, sin(x),cos(x),tan(x)
print *, sin(y),cos(y),tan(y)
print *,sin(x=3.141592653589793d0/2),cos(x=3.141592653589793d0),tan(x=3.141592653589793d0/4)
end program
