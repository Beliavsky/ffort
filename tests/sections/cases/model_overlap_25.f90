program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:5)
a(-4)=9
a(-3)=12
a(-2)=1
a(-1)=19
a(0)=-18
a(1)=6
a(2)=-3
a(3)=14
a(4)=8
a(5)=-12
lo=3
hi=3
s=3
rlo=-4
rhi=-4
rs=1
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-12)
print *, a,a(5:-4:-1)
end program probe
