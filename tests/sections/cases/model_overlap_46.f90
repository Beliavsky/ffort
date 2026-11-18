program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:9)
a(-2)=-3
a(-1)=-6
a(0)=-20
a(1)=-18
a(2)=5
a(3)=-20
a(4)=-15
a(5)=-15
a(6)=-10
a(7)=6
a(8)=2
a(9)=-5
lo=8
hi=4
s=-1
rlo=9
rhi=1
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-18)
print *, a,a(9:-2:-1)
end program probe
