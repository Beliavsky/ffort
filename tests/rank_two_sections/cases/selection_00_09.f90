program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(6,2),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(:,4:9:3)
print *,size(aa(:,4:9:3))
print *,size(aa(:,4:9:3),1)
print *,size(aa(:,4:9:3),2)
print *,lbound(aa(:,4:9:3),1),ubound(aa(:,4:9:3),1)
print *,lbound(aa(:,4:9:3),2),ubound(aa(:,4:9:3),2)
bb=aa(:,4:9:3)+2
print *,bb
aa(:,4:9:3)=aa(:,4:9:3)+1000
print *,aa
end program section_oracle
