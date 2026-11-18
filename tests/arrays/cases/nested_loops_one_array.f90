program probe
implicit none
integer :: a(6),i,j
do i=1,2
 do j=1,3
  a((i-1)*3+j)=10*i+j
 end do
end do
print *,a(1),a(2),a(3),a(4),a(5),a(6)
end program probe
