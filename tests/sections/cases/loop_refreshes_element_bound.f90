program probe
implicit none
integer :: i
integer :: a(1:4)
a(1)=1
a(2)=20
a(3)=30
a(4)=40
do i=1,3
print *, a(1:a(1))
a(1)=a(1)+1
end do
end program probe
