program probe
implicit none
integer :: lo,hi,s
integer :: a(1:5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
lo=1
hi=5
s=2
print *, a(lo:hi:s)
lo=5
hi=1
s=-2
print *, a(lo:hi:s)
end program probe
