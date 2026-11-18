program probe
implicit none
integer :: a(3)
a(1)=1
a(2)=2
a(3)=3
print *, a>2,2<a,a<=2,2>=a
end program probe
