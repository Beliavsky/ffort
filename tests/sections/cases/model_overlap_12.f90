program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(0:1)
a(0)=-17
a(1)=17
lo=1
hi=1
s=-2
rlo=0
rhi=0
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(1)+(17)
print *, a,a(1:0:-1)
end program probe
