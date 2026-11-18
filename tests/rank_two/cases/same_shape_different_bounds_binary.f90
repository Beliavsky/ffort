program independent_ranktwo
implicit none
integer :: aa(-1:0,3:5),bb(7:8,-4:-2),ii,jj
do jj=3,5
 do ii=-1,0
 aa(ii,jj)=ii+jj
 end do
end do
do jj=-4,-2
 do ii=7,8
 bb(ii,jj)=ii-jj
 end do
end do
print *,aa+bb,bb-aa
end program independent_ranktwo
