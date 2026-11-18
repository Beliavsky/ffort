program p
implicit none
integer::n(4)
real(8)::x(4)
n=[0,1,5,32]
x=[1d0,2d0,3d0,32d0]
print *,bessel_jn(n,x)
print *,bessel_yn(n,32d0)
print *,bessel_jn(2_8,x)
end program
