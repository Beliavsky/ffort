program main
implicit none
character(2)::a(1)
write(a(value()-6),'(i2.2)')7
print '(a)',a
contains
impure integer function value()
value=7
end function
end program
