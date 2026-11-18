program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(2:13)
a(2)=-1
a(3)=-7
a(4)=0
a(5)=10
a(6)=4
a(7)=-2
a(8)=7
a(9)=-19
a(10)=2
a(11)=18
a(12)=-13
a(13)=-17
lo=8
hi=10
s=-2
rlo=7
rhi=9
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-7)
print *, a,a(13:2:-1)
end program probe
