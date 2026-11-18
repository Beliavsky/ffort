program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:-1)
a(-2)=-17
a(-1)=-17
lo=-1
hi=-1
s=1
rlo=-2
rhi=-2
rs=-3
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-17)
print *, a,a(-1:-2:-1)
end program probe
