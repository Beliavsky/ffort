program p
implicit none
integer::n
real(8)::x
print *,kind(bessel_yn(n,x)),kind(erf(x)),kind(bessel_jn(999_8,x))
end program
