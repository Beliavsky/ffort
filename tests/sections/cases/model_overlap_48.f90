program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(-4:0)
a(-4)=-16
a(-3)=14
a(-2)=19
a(-1)=2
a(0)=8
lo=0
hi=0
s=1
rlo=-1
rhi=-1
rs=-1
a(lo:hi:s)=a(rlo:rhi:rs)*(2)+(8)
print *, a,a(0:-4:-1)
end program probe
