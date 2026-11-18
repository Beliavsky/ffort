program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(3:14)
a(3)=-14
a(4)=-18
a(5)=16
a(6)=-15
a(7)=-9
a(8)=-4
a(9)=10
a(10)=-10
a(11)=1
a(12)=14
a(13)=2
a(14)=-16
lo=13
hi=14
s=1
rlo=10
rhi=11
rs=1
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(14)
print *, a,a(14:3:-1)
end program probe
