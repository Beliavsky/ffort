program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:-2)
a(-4)=-10
a(-3)=12
a(-2)=5
lo=-3
hi=-5
s=2
rlo=-3
rhi=-1
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(5)
print *, a,a(-2:-4:-1)
end program probe
