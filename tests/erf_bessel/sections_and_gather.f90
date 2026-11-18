program p
implicit none
real(8)::x(3,2)
x=reshape([1d0,2d0,3d0,4d0,5d0,6d0],[3,2])
print *,erf(x(3:1:-1,2))
print *,bessel_j1(x([3,1,3],:))
end program
