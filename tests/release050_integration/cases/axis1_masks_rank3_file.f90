program p

implicit none
integer::a(3,2,2),g(3,2,2),b(3,2,2),i,j,k
character(4)::s(3,2,2)
do k=1,2
do j=1,2
do i=1,3
a(i,j,k)=100*k+10*j+i
end do
end do
end do
g=a([3,1,3],:,:)
b=shiftr(iand(g,maskr(4)),1)
do k=1,2
do j=1,2
do i=1,3
write(s(i,j,k),'(b4.4)')b(i,j,k)
end do
end do
end do
print '(a)',s
end program
