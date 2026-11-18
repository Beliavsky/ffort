program main
implicit none
integer::a(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
print '(2("[",2(i2),"]"))',a(2:1:-1,:)
end program
