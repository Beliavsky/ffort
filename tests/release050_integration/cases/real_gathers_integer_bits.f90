program p

implicit none
real::a(2,1,2),g(2,1,2)
real(8)::b(2,1,2),h(2,1,2)
integer::n(2,1,2),i,k
character(2)::s(2,1,2)
a(:,1,1)=[3.,5.]
a(:,1,2)=[9.,17.]
b(:,1,1)=[4.d0,8.d0]
b(:,1,2)=[16.d0,32.d0]
g=a(:,:,[2,1])
h=b([2,1],:,:)
n=shiftr(ior(int(g),int(h)),1)
do k=1,2
do i=1,2
write(s(i,1,k),'(z2.2)')n(i,1,k)
end do
end do
print '(a)',s
end program
