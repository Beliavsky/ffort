program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-3:3)
a(-3)=-20
a(-2)=7
a(-1)=3
a(0)=-1
a(1)=5
a(2)=-9
a(3)=-13
lo=-3
hi=-1
s=1
rlo=-3
rhi=3
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(-20)
print *, a,a(3:-3:-1)
end program probe
