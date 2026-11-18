program probe
implicit none
integer :: a(1:5)
a(1)=-3
a(2)=-2
a(3)=-1
a(4)=0
a(5)=1
print *, abs(a(::2)),int(real(a(2:4))),real(a(5:1:-2))
print *, mod(a(1:3),2),min(2,a(::2)),max(a(::2),-1)
end program probe
