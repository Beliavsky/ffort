program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(1:9)
a(1)=-5
a(2)=1
a(3)=9
a(4)=-7
a(5)=12
a(6)=-6
a(7)=3
a(8)=-5
a(9)=-9
lo=7
hi=5
s=-1
rlo=4
rhi=2
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(1)
print *, a,a(9:1:-1)
end program probe
