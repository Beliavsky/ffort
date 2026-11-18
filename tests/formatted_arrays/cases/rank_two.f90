program main
implicit none
integer::a(-1:0,3:5)
a=reshape([1,2,3,4,5,6],[2,3])
print '(3i3)',a
print '(2i4)',a(0:-1:-1,5:3:-1)

end program
