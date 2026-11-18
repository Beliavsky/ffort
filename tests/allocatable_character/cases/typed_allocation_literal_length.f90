program main
implicit none
character(:),allocatable::a(:)
allocate(character(len=len('A B'))::a(1))
a='abc'
print *,len(a)
print '(a)',a

end program
