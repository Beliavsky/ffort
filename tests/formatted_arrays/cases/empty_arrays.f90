program main
implicit none
integer::a(0),b(2,0)
character(3)::c(0)
print '(3i3)',a
print '("empty",3i3)',b
print '("left",3a,"right")',c
print '(2i2)',a,7
print '(a)',[character(0)::]
print '("literal")',a

end program
