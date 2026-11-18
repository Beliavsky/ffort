program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(1:12)
a(1)=11
a(2)=8
a(3)=3
a(4)=-20
a(5)=20
a(6)=19
a(7)=-20
a(8)=-3
a(9)=-7
a(10)=13
a(11)=-5
a(12)=9
lo=6
hi=7
s=1
rlo=1
rhi=4
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-3)
print *, a,a(12:1:-1)
end program probe
