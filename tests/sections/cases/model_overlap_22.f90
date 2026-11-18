program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-5:-3)
a(-5)=19
a(-4)=17
a(-3)=11
lo=-4
hi=-4
s=-2
rlo=-5
rhi=-5
rs=3
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(11)
print *, a,a(-3:-5:-1)
end program probe
