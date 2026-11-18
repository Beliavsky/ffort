program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-2:7)
a(-2)=9
a(-1)=17
a(0)=-10
a(1)=-17
a(2)=-11
a(3)=20
a(4)=-17
a(5)=-1
a(6)=0
a(7)=11
lo=3
hi=0
s=-3
rlo=0
rhi=-2
rs=-2
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(-1)
print *, a,a(7:-2:-1)
end program probe
