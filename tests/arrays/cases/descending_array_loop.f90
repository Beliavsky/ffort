program probe
implicit none
integer :: a(1:5),i
do i=5,1,-1
 a(i)=i*3
end do
print *,a(1),a(2),a(3),a(4),a(5),i
end program probe
