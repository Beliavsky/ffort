program probe
implicit none
integer :: a(-2*2:2**2-1)
a(-4)=8
a(3)=9
print *,a(-4),a(3)
end program probe
