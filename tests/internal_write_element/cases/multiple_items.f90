program main
implicit none
character(10)::a(2)
write(a(1),'(a,i2.2,1x,l1)')'n=',7,.true.
print '(a)',a(1)
end program
