program independent_ranktwo
implicit none
integer, parameter :: rows=2,cols=3,low=-2
integer :: aa(low:low+rows-1,cols),i,j
do j=1,cols
 do i=low,low+rows-1
 aa(i,j)=i+j
 end do
end do
print *, aa,size(aa,2),lbound(aa,1)
end program independent_ranktwo
