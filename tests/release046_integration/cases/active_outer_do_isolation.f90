program p
implicit none
integer::i,a(2)
do i=7,8
a=[(i,i=1,2)]
print '(3i3)',a,i
end do
end program
