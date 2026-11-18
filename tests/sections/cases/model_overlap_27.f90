program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-5:-2)
a(-5)=18
a(-4)=-3
a(-3)=19
a(-2)=-20
lo=-3
hi=-3
s=-3
rlo=-3
rhi=-3
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-20)
print *, a,a(-2:-5:-1)
end program probe
