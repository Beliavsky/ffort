program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-3:7)
a(-3)=-13
a(-2)=-14
a(-1)=15
a(0)=1
a(1)=-9
a(2)=-9
a(3)=8
a(4)=-6
a(5)=-9
a(6)=13
a(7)=2
lo=2
hi=2
s=-3
rlo=-1
rhi=-1
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(2)
print *, a,a(7:-3:-1)
end program probe
