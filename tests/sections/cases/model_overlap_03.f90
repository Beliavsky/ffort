program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:0)
a(-4)=-14
a(-3)=-18
a(-2)=6
a(-1)=20
a(0)=-14
lo=-1
hi=0
s=-1
rlo=-1
rhi=-4
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-14)
print *, a,a(0:-4:-1)
end program probe
