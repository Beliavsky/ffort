program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:7)
a(-2)=19
a(-1)=2
a(0)=11
a(1)=-20
a(2)=18
a(3)=-5
a(4)=6
a(5)=-4
a(6)=-20
a(7)=11
lo=3
hi=4
s=1
rlo=-1
rhi=-2
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(19)
print *, a,a(7:-2:-1)
end program probe
