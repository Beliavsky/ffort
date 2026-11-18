program p
implicit none
real(8)::x
x=0d0
print *,erf(x),bessel_j0(x),bessel_j1(x),bessel_jn(5,x)
x=tiny(x)
print *,erf(x),bessel_j1(x),bessel_jn(1,x)
end program
