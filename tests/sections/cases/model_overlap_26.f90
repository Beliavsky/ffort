program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(2:3)
a(2)=-10
a(3)=-6
lo=3
hi=3
s=2
rlo=3
rhi=3
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-6)
print *, a,a(3:2:-1)
end program probe
