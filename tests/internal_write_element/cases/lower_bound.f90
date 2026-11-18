program main
implicit none
character(3)::a(-2:0)
a='old'
write(a(-1),'(i0)')17
print '(a)',a
end program
