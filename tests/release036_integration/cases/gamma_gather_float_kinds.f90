program main
implicit none
real(8)::a(3,2)
real(4)::s(2)
a=reshape([1d0,2d0,3d0,4d0,5d0,6d0],[3,2])
s=sign([0.0,2.0],[-0.0,0.0])
print *,log_gamma(a([3,1],:))
write(*,'("zero:",4(1x,i0))')int(sign(1.0,s)),kind(s),kind(log_gamma(a))
end program
