program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(2:12)
a(2)=-2
a(3)=20
a(4)=-15
a(5)=14
a(6)=-11
a(7)=10
a(8)=-10
a(9)=11
a(10)=-11
a(11)=10
a(12)=-10
lo=11
hi=8
s=3
rlo=11
rhi=12
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-10)
print *, a,a(12:2:-1)
end program probe
