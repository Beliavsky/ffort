program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:1)
a(-4)=19
a(-3)=-4
a(-2)=19
a(-1)=2
a(0)=-20
a(1)=-19
lo=-2
hi=-2
s=-1
rlo=-3
rhi=-3
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-20)
print *, a,a(1:-4:-1)
end program probe
