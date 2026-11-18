program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(3),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(1,8:4:-2)
print *,size(aa(1,8:4:-2))
print *,size(aa(1,8:4:-2),1)
print *,lbound(aa(1,8:4:-2),1),ubound(aa(1,8:4:-2),1)
bb=aa(1,8:4:-2)+2
print *,bb
aa(1,8:4:-2)=aa(1,8:4:-2)+1000
print *,aa
end program section_oracle
