program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:0)
a(-2)=17
a(-1)=5
a(0)=-9
lo=-1
hi=-1
s=-3
rlo=-2
rhi=-2
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-9)
print *, a,a(0:-2:-1)
end program probe
