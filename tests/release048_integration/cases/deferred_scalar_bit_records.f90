program p
implicit none
character(:),allocatable::s,a(:)
integer::i
s='Ab '
a=[s,s]
print '(*(a))','[',a,']'
print '(z8.8,b4.4)',not(0),iand(15,5)
end program
