program p
implicit none
integer::i,a(4)
logical::v(4)
character(:),allocatable::s,c(:)
a=[1,2,4,8]
v=btest(a,[0_8,1_8,2_8,3_8])
s='Y '
c=[(s,i=1,4)]
print '(*(l1,a))',(v(i),c(i),i=1,4)
end program
