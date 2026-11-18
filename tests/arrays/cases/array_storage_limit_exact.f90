program probe
implicit none
integer :: a(65536)
a(1)=4
a(65536)=5
print *,a(1),a(65536)
end program probe
