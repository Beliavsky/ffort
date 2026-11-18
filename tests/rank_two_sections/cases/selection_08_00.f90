program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(0,5),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(-20:-21,:)
print *,size(aa(-20:-21,:))
print *,size(aa(-20:-21,:),1)
print *,size(aa(-20:-21,:),2)
print *,lbound(aa(-20:-21,:),1),ubound(aa(-20:-21,:),1)
print *,lbound(aa(-20:-21,:),2),ubound(aa(-20:-21,:),2)
bb=aa(-20:-21,:)+2
print *,bb
aa(-20:-21,:)=aa(-20:-21,:)+1000
print *,aa
end program section_oracle
