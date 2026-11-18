program p

implicit none
integer,allocatable::a(:,:,:)
integer::i,j,k
character(4)::s(4)
allocate(a(2,2,3))
do k=1,3
do j=1,2
do i=1,2
a(i,j,k)=100*k+10*j+i
end do
end do
end do
a=a(:,:,[3,1,3,2])
if(size(a,3)/=4)error stop 'extent'
do k=1,4
write(s(k),'(z4.4)')iand(a(1,1,k),maskr(8))
end do
print '(a)',s
end program
