program rankthree
implicit none
integer :: aa(-1:1,2:3,4:6),i,j,k,lo,hi,st
do k=4,6
do j=2,3
do i=-1,1
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
lo=6
hi=4
st=-2
print *,aa(:,3,lo:hi:st)
aa(:,3,lo:hi:st)=9
print *,aa
end program rankthree
