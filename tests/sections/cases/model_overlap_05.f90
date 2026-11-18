program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-3:3)
a(-3)=-11
a(-2)=20
a(-1)=14
a(0)=14
a(1)=-10
a(2)=1
a(3)=13
lo=-1
hi=1
s=2
rlo=-3
rhi=-2
rs=1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-10)
print *, a,a(3:-3:-1)
end program probe
