program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-1:0)
a(-1)=10
a(0)=18
lo=-1
hi=-1
s=-2
rlo=0
rhi=0
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(10)
print *, a,a(0:-1:-1)
end program probe
