program probe
implicit none
integer :: a(-1:1)
a(-1)=4
a(0)=5
a(1)=6
print *,a(-1)+a(0)+a(1)
end program probe
