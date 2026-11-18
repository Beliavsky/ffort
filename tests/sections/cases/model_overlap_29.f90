program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(2:9)
a(2)=9
a(3)=16
a(4)=-4
a(5)=11
a(6)=-17
a(7)=-18
a(8)=-9
a(9)=-9
lo=9
hi=9
s=3
rlo=4
rhi=4
rs=1
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-9)
print *, a,a(9:2:-1)
end program probe
