program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
aa(2:0:-1,6:4:-2)=2*aa(1:-1:-1,8:7:-1)-7
print *,aa
end program section_oracle
