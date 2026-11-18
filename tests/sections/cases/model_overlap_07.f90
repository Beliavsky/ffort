program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(1:2)
a(1)=-14
a(2)=15
lo=1
hi=-1
s=2
rlo=1
rhi=3
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-14)
print *, a,a(2:1:-1)
end program probe
