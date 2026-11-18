program probe
implicit none
integer :: a(6)
a(2:6:2)=7
print *, a(6:2:-2)
end program probe
