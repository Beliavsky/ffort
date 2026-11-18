program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:2)
a(-2)=-13
a(-1)=1
a(0)=16
a(1)=-19
a(2)=15
lo=0
hi=0
s=-3
rlo=-2
rhi=-2
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(16)
print *, a,a(2:-2:-1)
end program probe
