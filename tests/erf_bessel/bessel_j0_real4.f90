program p
implicit none
real(4)::x
integer(8)::n

n=5
x=0.17_4
print *,bessel_j0(x),bessel_j0(x=x),kind(bessel_j0(x))
end program
