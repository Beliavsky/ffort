program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:-3)
a(-4)=-5
a(-3)=14
lo=-3
hi=-4
s=1
rlo=-4
rhi=-3
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-5)
print *, a,a(-3:-4:-1)
end program probe
