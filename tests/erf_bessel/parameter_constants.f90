program p
implicit none
real(8),parameter::a=erf(0.17d0),b=bessel_jn(5,1d0),c=bessel_yn(5,1d0)
print *,a,b,c
end program
