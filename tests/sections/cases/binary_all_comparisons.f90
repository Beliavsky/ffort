program probe
implicit none
integer :: a(1:3)
a(1)=1
a(2)=2
a(3)=3
print *, a(:)<a(3:1:-1),a(:)<=a(3:1:-1),a(:)==a(3:1:-1)
print *, a(:)/=a(3:1:-1),a(:)>a(3:1:-1),a(:)>=a(3:1:-1)
end program probe
