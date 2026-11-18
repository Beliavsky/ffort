program p
implicit none
real(8)::x
x=1048576d0
print *,bessel_j0(x),bessel_j1(-x),bessel_jn(32,x),bessel_yn(32,x)
x=0.00000095367431640625d0
print *,bessel_y0(x),bessel_y1(x),bessel_yn(32,x)
end program
