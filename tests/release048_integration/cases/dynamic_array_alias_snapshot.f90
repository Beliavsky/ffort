program p
implicit none
character(:),allocatable::a(:)
integer::i
a=['AB','cd']
a=[(a,i=1,2)]
print '(*(a))','[',a,']'
print '(4z2.2)',[(ieor(i,3),i=0,3)]
end program
