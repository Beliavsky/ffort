program independent_ranktwo
implicit none
integer :: aa(2,3),i,j
do j=1,3
 do i=1,2
 aa(i,j)=10*j+i
 end do
end do
aa=aa+aa(1,1)
print *, aa
end program independent_ranktwo
