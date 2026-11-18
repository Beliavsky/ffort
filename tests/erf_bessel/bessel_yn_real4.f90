program p
implicit none
real(4)::x
integer(8)::n

n=5
x=0.17_4
print *,bessel_yn(n,x),bessel_yn(x=x,n=n),kind(bessel_yn(n,x))
end program
