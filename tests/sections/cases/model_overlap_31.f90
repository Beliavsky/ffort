program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(3:14)
a(3)=-16
a(4)=3
a(5)=8
a(6)=-8
a(7)=-12
a(8)=-10
a(9)=18
a(10)=-13
a(11)=15
a(12)=-6
a(13)=-20
a(14)=-18
lo=11
hi=11
s=-3
rlo=10
rhi=10
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(8)
print *, a,a(14:3:-1)
end program probe
