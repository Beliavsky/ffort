program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:1)
a(-2)=13
a(-1)=-14
a(0)=10
a(1)=-10
lo=-2
hi=0
s=2
rlo=-2
rhi=1
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(10)
print *, a,a(1:-2:-1)
end program probe
