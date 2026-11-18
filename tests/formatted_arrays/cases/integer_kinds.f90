program main
implicit none
integer::a(3)=[1,-22,333]
integer(8)::b(2)=[2147483648_8,-9223372036854775807_8]
print '(3i5,2i23)',a,b
print '(3i0.4)',a
print '(2i2)',a

end program
