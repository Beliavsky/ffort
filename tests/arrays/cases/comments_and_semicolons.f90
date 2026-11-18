program probe
implicit none
integer :: a(2) ! dimensions
real :: b(-1:0)
a(1)=5 ! first value
a(2)=9; b(-1)=0.5; b(0)=a(2)/2.0
print *,"array!",a(1),a(2),b(-1),b(0)
end program probe
