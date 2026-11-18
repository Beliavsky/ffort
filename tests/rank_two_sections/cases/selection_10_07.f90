program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(0),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(-2,6:5)
print *,size(aa(-2,6:5))
print *,size(aa(-2,6:5),1)
print *,lbound(aa(-2,6:5),1),ubound(aa(-2,6:5),1)
bb=aa(-2,6:5)+2
print *,bb
aa(-2,6:5)=aa(-2,6:5)+1000
print *,aa
end program section_oracle
