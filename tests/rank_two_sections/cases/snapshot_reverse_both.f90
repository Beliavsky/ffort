program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
aa(:,:)=aa(3:-2:-1,8:4:-1)
print *,aa
end program section_oracle
