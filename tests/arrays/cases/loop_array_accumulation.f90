program probe
implicit none
integer :: a(-3:3),i,s
s=0
do i=-3,3
 a(i)=i*i
 s=s+a(i)
end do
print *,s,a(-3),a(0),a(3),i
end program probe
