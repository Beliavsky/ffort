program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:1)
a(-4)=-13
a(-3)=8
a(-2)=11
a(-1)=10
a(0)=3
a(1)=-5
lo=-3
hi=-6
s=3
rlo=-2
rhi=1
rs=-3
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-13)
print *, a,a(1:-4:-1)
end program probe
