program rankthree
implicit none
integer :: aa(-1:1,2:3,4:6),bb(2),i,j,k
do k=4,6
do j=2,3
do i=-1,1
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
bb=aa(0,:,5)+3
print *,aa(0,:,5),bb
print *,size(aa(0,:,5))
print *,size(aa(0,:,5),1),lbound(aa(0,:,5),1),ubound(aa(0,:,5),1)
end program rankthree
