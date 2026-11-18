program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-5:6)
a(-5)=8
a(-4)=14
a(-3)=-19
a(-2)=-7
a(-1)=-17
a(0)=-10
a(1)=5
a(2)=2
a(3)=18
a(4)=2
a(5)=20
a(6)=-15
lo=2
hi=0
s=-2
rlo=-2
rhi=-4
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(2)
print *, a,a(6:-5:-1)
end program probe
