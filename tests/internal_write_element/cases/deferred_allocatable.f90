program main
implicit none
character(:),allocatable::a(:)
allocate(character(3)::a(2))
a='old'
write(a(2),'(i0)')7
print '(a)',a
end program
