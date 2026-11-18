program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(3:6)
a(3)=-15
a(4)=5
a(5)=2
a(6)=-18
lo=3
hi=5
s=-2
rlo=4
rhi=5
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(5)
print *, a,a(6:3:-1)
end program probe
