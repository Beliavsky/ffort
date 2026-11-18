program probe
implicit none
integer :: a(5:7)
a(5)=50
a(6)=60
a(7)=70
print *,a(7),a(5),a(6)
end program probe
