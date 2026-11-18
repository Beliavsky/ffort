program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(1:12)
a(1)=9
a(2)=-17
a(3)=18
a(4)=2
a(5)=13
a(6)=-10
a(7)=3
a(8)=13
a(9)=2
a(10)=-11
a(11)=-11
a(12)=2
lo=9
hi=10
s=1
rlo=1
rhi=4
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-11)
print *, a,a(12:1:-1)
end program probe
