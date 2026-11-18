program p
implicit none
real :: a(3)
character(18) :: line(2)
a=[1.5,-2.0,3.5]
line='unchanged'
write(line(2),'(3f6.1)')a([3,1,3])
write(*,'(a)')line(1),line(2)
end program
