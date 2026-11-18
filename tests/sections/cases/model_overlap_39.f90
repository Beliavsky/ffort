program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:3)
a(-4)=18
a(-3)=0
a(-2)=2
a(-1)=-7
a(0)=17
a(1)=0
a(2)=-15
a(3)=-13
lo=-1
hi=2
s=3
rlo=3
rhi=0
rs=-3
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-13)
print *, a,a(3:-4:-1)
end program probe
