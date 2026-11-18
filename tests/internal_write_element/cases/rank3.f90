program main
implicit none
character(2)::a(0:1,2:2,-1:0)
a='xx'
write(a(1,2,0),'(i2.2)')7
print '(a)',a
end program
