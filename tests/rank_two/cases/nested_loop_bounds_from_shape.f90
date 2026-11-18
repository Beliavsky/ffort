program independent_ranktwo
implicit none
integer :: aa(-2:1,3:4),ii,jj,acc
aa=0
acc=0
do jj=lbound(aa,2),ubound(aa,2)
 do ii=lbound(aa,1),ubound(aa,1)
 aa(ii,jj)=ii*jj
 acc=acc+aa(ii,jj)
 end do
end do
print *,aa,acc
end program independent_ranktwo
