program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(6),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(:,6)
print *,size(aa(:,6))
print *,size(aa(:,6),1)
print *,lbound(aa(:,6),1),ubound(aa(:,6),1)
bb=aa(:,6)+2
print *,bb
aa(:,6)=aa(:,6)+1000
print *,aa
end program section_oracle
