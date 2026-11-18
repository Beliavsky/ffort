program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j,ss,tt
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
ss=2147483647
tt=-2147483647-1
print *,aa(-2:3:ss,4:8:ss),aa(3:-2:tt,8:4:tt)
print *,size(aa(::tt,:)),size(aa(:,::tt))
end program section_oracle
