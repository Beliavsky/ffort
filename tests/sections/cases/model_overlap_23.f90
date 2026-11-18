program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-3:1)
a(-3)=-4
a(-2)=8
a(-1)=-12
a(0)=-14
a(1)=9
lo=-1
hi=-2
s=-1
rlo=1
rhi=-2
rs=-3
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-4)
print *, a,a(1:-3:-1)
end program probe
