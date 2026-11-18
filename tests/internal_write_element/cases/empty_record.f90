program main
implicit none
character(4)::a(1)
a='old!'
write(a(1),'(a)')''
print '(a)',a(1)
end program
