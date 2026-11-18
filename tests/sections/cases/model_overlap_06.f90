program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:7)
a(-4)=17
a(-3)=4
a(-2)=18
a(-1)=-13
a(0)=-17
a(1)=6
a(2)=8
a(3)=-9
a(4)=-11
a(5)=-7
a(6)=-8
a(7)=15
lo=0
hi=3
s=-3
rlo=2
rhi=1
rs=1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(-13)
print *, a,a(7:-4:-1)
end program probe
