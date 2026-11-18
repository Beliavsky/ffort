program p
implicit none
integer::a(65)
character(:),allocatable::s,c(:)
s='SAFE'
c=[s]
write(*,'(a)',advance='no')c
a=ior(0,1)
print '(*(b0.1024))',a
end program
