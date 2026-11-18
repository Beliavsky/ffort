program p
implicit none
character(:),allocatable::s,a(:)
s='abcdefgh'
a=[s]
print '(a,tl4,z2.2,tr1,b2.2)',a,ieor(7,8),1
end program
