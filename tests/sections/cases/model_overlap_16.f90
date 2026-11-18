program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:0)
a(-2)=-14
a(-1)=13
a(0)=-3
lo=-1
hi=-1
s=-2
rlo=-1
rhi=-1
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(-14)
print *, a,a(0:-2:-1)
end program probe
