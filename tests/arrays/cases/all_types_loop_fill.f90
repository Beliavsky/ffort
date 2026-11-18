program probe
implicit none
integer :: a(-2:2),i
real :: b(-2:2)
logical :: c(-2:2)
do i=-2,2
 a(i)=i*2
 b(i)=real(a(i))/4.0
 c(i)=a(i)>0
end do
print *,a(-2),b(-2),c(-2),a(0),b(0),c(0),a(2),b(2),c(2)
end program probe
