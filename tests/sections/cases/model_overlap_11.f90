program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(2:6)
a(2)=10
a(3)=-17
a(4)=14
a(5)=9
a(6)=6
lo=5
hi=7
s=-2
rlo=6
rhi=4
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(9)
print *, a,a(6:2:-1)
end program probe
