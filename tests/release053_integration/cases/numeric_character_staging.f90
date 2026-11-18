program p
implicit none
integer::x(3),v(3),i
character(4)::labels(3),chosen(2)
x=[10,20,30]
v=x([3,1,2])
do i=1,3
 write(labels(i),'(i4)')v(i)
end do
chosen=labels([3,1])
write(*,'(a,a,a,a,a)')'[',chosen(1),'][',chosen(2),']'
end program
