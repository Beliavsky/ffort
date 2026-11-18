program p
implicit none
real(4)::x
integer(8)::n

n=5
x=0.17_4
print *,bessel_y0(x),bessel_y0(x=x),kind(bessel_y0(x))
end program
