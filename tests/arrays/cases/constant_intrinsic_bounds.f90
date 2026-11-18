program probe
implicit none
integer :: a(-abs(2):max(1,3))
a(-2)=11
a(3)=22
print *,a(-2),a(3)
end program probe
