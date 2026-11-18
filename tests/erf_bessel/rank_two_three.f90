program p
implicit none
real(8)::x(2,2)
real::y(2,1,2)
x=reshape([1d0,2d0,3d0,4d0],[2,2])
y=2.
y(1,1,1)=1.
y(1,1,2)=3.
y(2,1,2)=4.
print *,erf(x),bessel_j0(x),bessel_y1(x)
print *,bessel_jn(2,y),bessel_yn(2,y)
end program
