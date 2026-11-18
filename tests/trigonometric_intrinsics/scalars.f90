program scalars
implicit none
real :: x
real(8) :: y
real, parameter :: a=sin(0.5)
real(8), parameter :: b=cos(x=0.5d0)
x=-0.75
y=-0.75d0
print *, sin(x),cos(x),tan(x),kind(sin(x)),kind(cos(x)),kind(tan(x))
print *, sin(y),cos(y),tan(y),kind(sin(y)),kind(cos(y)),kind(tan(y))
print *, a,b,sin(0.0),cos(0.0d0),tan(0.0)
print *, sin(x=0.125d0),cos(x=-0.125),tan(x=1000.0d0)
end program
