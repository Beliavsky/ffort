program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(3:9)
a(3)=-14
a(4)=-12
a(5)=-5
a(6)=8
a(7)=6
a(8)=16
a(9)=20
lo=9
hi=9
s=2
rlo=8
rhi=8
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-5)
print *, a,a(9:3:-1)
end program probe
