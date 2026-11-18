program main
implicit none
integer::a(2)=[1,2]
print '(4i3)',a
print '(2i3,"tail",a)',a
print '(a,i3)',"only"

end program
