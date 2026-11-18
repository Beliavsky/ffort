program p
implicit none
integer :: a(3),b(2),i
a=[1,2,3]
i=1
do while(i<=3)
 b=a([3,1])
 write(*,'(2i4)')b
 a=a+10
 i=i+1
end do
end program
