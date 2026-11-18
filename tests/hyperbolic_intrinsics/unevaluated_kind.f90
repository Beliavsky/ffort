program unevaluated_kind
implicit none
real :: x,a(2)
real(8) :: y,b(2,2)
print *,kind(sinh(x)),kind(cosh(y)),kind(tanh(a)),kind(cosh(b))
x=1000.0
y=1000.0d0
print *,kind(sinh(x)),kind(cosh(y))
end program
