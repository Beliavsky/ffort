program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-1:3)
a(-1)=8
a(0)=14
a(1)=20
a(2)=20
a(3)=-1
lo=-1
hi=-1
s=3
rlo=0
rhi=0
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(20)
print *, a,a(3:-1:-1)
end program probe
