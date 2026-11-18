program main
implicit none
character(3),allocatable::a(:)
allocate(a(-1:1))
a='old'
write(a(0),'(i0)')7
print '(a)',a
end program
