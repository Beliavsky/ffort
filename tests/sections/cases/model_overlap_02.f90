program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(0:8)
a(0)=3
a(1)=20
a(2)=-9
a(3)=14
a(4)=-18
a(5)=19
a(6)=7
a(7)=-20
a(8)=3
lo=8
hi=7
s=-1
rlo=4
rhi=6
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(19)
print *, a,a(8:0:-1)
end program probe
