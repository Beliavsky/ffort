program main
implicit none
character(4)::a(3)
a='old!'
write(a(2),'(i2.2)')7
print '(a)',a
end program
