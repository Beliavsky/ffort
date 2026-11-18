program p

implicit none
integer(8)::a(2,3,2),g(2,2,2),b(2,2,2)
integer::i,j,k
character(16)::s(2,2,2)
do k=1,2
do j=1,3
do i=1,2
a(i,j,k)=100_8*k+10_8*j+i
end do
end do
end do
g=a(:,[3,1],:)
b=ior(iand(g,maskr(8,kind=8)),maskl(4,kind=8))
do k=1,2
do j=1,2
do i=1,2
write(s(i,j,k),'(z16.16)')b(i,j,k)
end do
end do
end do
print '(a)',s
end program
