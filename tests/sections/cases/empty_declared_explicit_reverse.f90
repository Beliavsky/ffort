program probe
implicit none
integer :: a(5:3),b(0),c(-2:-3)
print *, 1,a(3:5:-1),2,b(0:1:-1),3,c(-3:-2:-1),4
end program probe
