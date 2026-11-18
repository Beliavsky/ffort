program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(0:10)
a(0)=5
a(1)=-1
a(2)=16
a(3)=17
a(4)=17
a(5)=-17
a(6)=-16
a(7)=-13
a(8)=12
a(9)=13
a(10)=-16
lo=0
hi=1
s=-1
rlo=4
rhi=2
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(17)
print *, a,a(10:0:-1)
end program probe
