program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:2)
a(-2)=-3
a(-1)=-15
a(0)=-3
a(1)=2
a(2)=-1
lo=-1
hi=2
s=-3
rlo=-1
rhi=0
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-3)
print *, a,a(2:-2:-1)
end program probe
