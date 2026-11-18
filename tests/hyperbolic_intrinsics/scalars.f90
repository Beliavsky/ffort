program scalars
implicit none
real :: x
real(8) :: y
real, parameter :: a=sinh(0.5)
real(8), parameter :: b=cosh(x=0.5d0)
x=-0.75
y=-0.75d0
print *, sinh(x),cosh(x),tanh(x),kind(sinh(x)),kind(cosh(x)),kind(tanh(x))
print *, sinh(y),cosh(y),tanh(y),kind(sinh(y)),kind(cosh(y)),kind(tanh(y))
print *, a,b,sinh(0.0),cosh(0.0d0),tanh(0.0)
print *, sinh(x=0.125d0),cosh(x=-0.125),tanh(x=1000.0d0)
end program
