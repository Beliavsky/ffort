program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(1:9)
a(1)=3
a(2)=7
a(3)=-14
a(4)=-10
a(5)=5
a(6)=19
a(7)=11
a(8)=-19
a(9)=1
lo=4
hi=1
s=3
rlo=2
rhi=5
rs=-3
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(19)
print *, a,a(9:1:-1)
end program probe
