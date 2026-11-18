program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(3:6)
a(3)=-17
a(4)=-7
a(5)=10
a(6)=3
lo=3
hi=3
s=-3
rlo=3
rhi=3
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(-2)+(-7)
print *, a,a(6:3:-1)
end program probe
