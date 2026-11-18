program p

implicit none
character(:),allocatable::s(:,:,:)
character(12)::fmt
integer::j,k
allocate(character(6)::s(1,2,2))
fmt='(i6.6)'
do k=1,2
do j=1,2
write(s(1,j,k),fmt)maskr(j+k)
end do
end do
print '(a)',s
end program
