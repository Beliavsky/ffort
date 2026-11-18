program probe
implicit none
integer :: a(-1:0)
real :: b(3:4)
logical :: c(-3:-2)
a(-1)=5
a(0)=7
b(3)=0.25
b(4)=1.75
c(-3)=.true.
c(-2)=.false.
a(-1)=a(0)+1
b(3)=b(4)-0.5
c(-2)=.not.c(-3)
print *,a(-1),a(0),b(3),b(4),c(-3),c(-2)
end program probe
