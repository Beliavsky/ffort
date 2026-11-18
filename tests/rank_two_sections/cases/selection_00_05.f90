program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(6,0),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(:,:8:-1)
print *,size(aa(:,:8:-1))
print *,size(aa(:,:8:-1),1)
print *,size(aa(:,:8:-1),2)
print *,lbound(aa(:,:8:-1),1),ubound(aa(:,:8:-1),1)
print *,lbound(aa(:,:8:-1),2),ubound(aa(:,:8:-1),2)
bb=aa(:,:8:-1)+2
print *,bb
aa(:,:8:-1)=aa(:,:8:-1)+1000
print *,aa
end program section_oracle
