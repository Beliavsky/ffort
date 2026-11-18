program main
implicit none
character(2)::a(-1:0,3:4)
a='xx'
write(a(0,3),'(i2.2)')7
print '(a)',a
end program
