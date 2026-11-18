program unevaluated_kind
implicit none
real :: x,a(2)
real(8) :: y,b(2,2)
print *,kind(sin(x)),kind(cos(y)),kind(tan(a)),kind(cos(b))
x=1000.0
y=1000.0d0
print *,kind(sin(x)),kind(cos(y))
end program
