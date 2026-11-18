program main
implicit none
character(3),allocatable::a(:,:),b(:,:)
allocate(a(-1:0,3:5))
a='abcdef'
a(:,4)='xy'
b=a
print *,len(b),size(b),lbound(b,1),lbound(b,2)
print '(6a4)',b

end program
