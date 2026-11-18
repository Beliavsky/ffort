program probe
implicit none
integer :: a(3),b(3),c(3)
a(1)=2
b(2)=3
c(3)=17
print *,c(b(a(1)))
end program probe
