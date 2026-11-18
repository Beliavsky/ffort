program probe
implicit none
integer :: a(2)
real :: b(2)
a(1)=-7
a(2)=3
b(1)=-2.5
b(2)=1.25
print *,abs(a(1)),mod(a(1),a(2)),min(a(1),a(2)),max(b(1),b(2)),int(b(1)),real(a(2))
end program probe
