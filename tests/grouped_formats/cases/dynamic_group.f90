program main
implicit none
integer::a(5),n
a=[1,2,3,4,5]
n=5
print '("P",2(i2),"E")',a(:n)
end program
