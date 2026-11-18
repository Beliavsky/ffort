program p
implicit none
character(:),allocatable::a(:)
integer::i,idx(2)=[1,1]
a=['aa','bb']
forall(i=1:2) a(idx(i))=achar(64+i)//'!'
print *,a
end program
