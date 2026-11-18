program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-5:-1)
a(-5)=13
a(-4)=-9
a(-3)=-11
a(-2)=-15
a(-1)=14
lo=-2
hi=-2
s=2
rlo=-4
rhi=-4
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-9)
print *, a,a(-1:-5:-1)
end program probe
