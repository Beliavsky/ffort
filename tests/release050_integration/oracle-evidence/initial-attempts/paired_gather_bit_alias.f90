program p

implicit none
integer::a(2,1,2),g(2,1,2),i,k
character(4)::s(2,1,2)
a(:,1,1)=[1,2]
a(:,1,2)=[8,4]
g=ior(a([2,1],:,:),a([1,2],:,:))
do k=1,2
do i=1,2
write(s(i,1,k),'(b4.4)')g(i,1,k)
end do
end do
print '(a)',s
end program
