program p

implicit none
integer::a(-1:0,4:5,-1:0),g(2,2,3),i,j,k
character(3)::s(2,2,3)
do k=-1,0
do j=4,5
do i=-1,0
a(i,j,k)=(k+2)*16+(j-4)*4+(i+1)
end do
end do
end do
g=shiftr(a(:,:,[0,-1,0]),1)
do k=1,3
do j=1,2
do i=1,2
write(s(i,j,k),'(i3.3)')g(i,j,k)
end do
end do
end do
print '(a)',s
end program
