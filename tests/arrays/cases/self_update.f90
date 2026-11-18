program probe
implicit none
integer :: a(2)
a(1)=2
a(2)=4
a(1)=a(1)*a(2)
print *,a(1),a(2)
end program probe
