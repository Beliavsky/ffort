program probe
implicit none
integer :: a(3:2)
integer :: i
do i=3,2
 a(i)=1
end do
if(.false.) then
 print *,a(3)
end if
print *,i
end program probe
