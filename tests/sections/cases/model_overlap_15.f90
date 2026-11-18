program probe
implicit none
integer :: lo,hi,s,rlo,rhi,rs
integer :: a(0:1)
a(0)=-12
a(1)=-7
lo=0
hi=-1
s=1
rlo=1
rhi=-1
rs=2
a(lo:hi:s)=a(rlo:rhi:rs)*(-1)+(-7)
print *, a,a(1:0:-1)
end program probe
