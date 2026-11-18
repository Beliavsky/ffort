program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:6)
a(-2)=-14
a(-1)=8
a(0)=-13
a(1)=1
a(2)=-20
a(3)=4
a(4)=9
a(5)=-3
a(6)=18
lo=4
hi=2
s=-2
rlo=4
rhi=6
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(1)
print *, a,a(6:-2:-1)
end program probe
