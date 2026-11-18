program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-5:6)
a(-5)=-1
a(-4)=-9
a(-3)=11
a(-2)=-15
a(-1)=-9
a(0)=-3
a(1)=14
a(2)=8
a(3)=18
a(4)=17
a(5)=3
a(6)=1
lo=5
hi=4
s=1
rlo=1
rhi=0
rs=1
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(18)
print *, a,a(6:-5:-1)
end program probe
