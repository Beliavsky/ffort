program main
implicit none
character(2)::a(1)
write(a(1),'(i2.2)')value()
print '(a)',a
contains
integer function value()
value=7
end function
end program
