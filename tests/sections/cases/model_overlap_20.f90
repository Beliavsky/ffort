program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-5:4)
a(-5)=-12
a(-4)=-15
a(-3)=11
a(-2)=13
a(-1)=-17
a(0)=-5
a(1)=-10
a(2)=6
a(3)=-10
a(4)=-13
lo=1
hi=1
s=-1
rlo=-3
rhi=-3
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(-15)
print *, a,a(4:-5:-1)
end program probe
