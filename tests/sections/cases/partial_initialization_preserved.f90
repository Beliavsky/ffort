program probe
implicit none
integer :: a(5)
a(1:5:2)=8
print *, a(2:4:2)
end program probe
